//
//  ContentScriptHarness.swift
//  FeedBlockerTests
//

import Foundation
import JavaScriptCore

/// Loads one of the extension's content scripts into a JavaScriptCore context backed by a
/// minimal fake of the browser APIs it touches (`location`, `history`, `document`,
/// `MutationObserver`, timers, and `browser.storage`).
///
/// This lets the blocking logic be exercised without Safari or a live website. It does not
/// evaluate CSS, so it verifies *when* the `no-feed` class is applied and *which* routes get
/// redirected — not whether the site's current markup matches the selectors.
final class ContentScriptHarness {
    enum HarnessError: Error, CustomStringConvertible {
        case javaScript(String)

        var description: String {
            switch self {
            case .javaScript(let message): return "JavaScript exception: \(message)"
            }
        }
    }

    /// `Shared (Extension)/Resources`, resolved relative to this source file.
    static let resourcesURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Shared (Extension)/Resources")

    private let context: JSContext
    private var pendingException: String?

    /// - Parameters:
    ///   - script: File name of the content script inside the extension's Resources folder.
    ///   - path: The page's initial `location.pathname`.
    ///   - storage: Initial contents of `browser.storage.local`.
    init(script: String, path: String = "/", storage: [String: Bool] = [:]) throws {
        guard let context = JSContext() else {
            throw HarnessError.javaScript("Unable to create JSContext")
        }
        self.context = context

        context.exceptionHandler = { [weak self] _, exception in
            self?.pendingException = exception?.toString() ?? "unknown error"
        }

        let storageJSON = String(decoding: try JSONSerialization.data(withJSONObject: storage), as: UTF8.self)
        let pathJSON = String(decoding: try JSONSerialization.data(withJSONObject: [path]), as: UTF8.self)

        try evaluate("var __fb = { storage: \(storageJSON), path: \(pathJSON)[0] };")
        try evaluate(Self.fakeBrowserEnvironment)

        // Mirror manifest.json: the shared engine loads before each site script.
        for file in ["blocker.js", script] {
            let source = try String(contentsOf: Self.resourcesURL.appending(path: file), encoding: .utf8)
            try evaluate(source)
        }

        // The script's `browser.storage.local.get(...).then(...)` resolves on the microtask
        // queue, which JavaScriptCore drains once each top-level evaluation returns.
        try evaluate("void 0;")
    }

    // MARK: - Page state

    /// Whether the content script has added `no-feed` to `<html>`, which activates the CSS rules.
    var hidesFeed: Bool { hasClass("no-feed") }

    /// Whether `<html>` currently has the given class.
    func hasClass(_ name: String) -> Bool {
        bool("document.documentElement.classList.contains(\(jsString(name)))")
    }

    /// URLs passed to `location.replace(...)`.
    var redirects: [String] { strings("__fb.replacedWith") }

    /// URLs passed to `location.assign(...)`.
    var assignments: [String] { strings("__fb.assignedWith") }

    var activeIntervalCount: Int { Int(context.evaluateScript("__fb.activeIntervalCount()").toInt32()) }

    var activeObserverCount: Int { Int(context.evaluateScript("__fb.activeObserverCount()").toInt32()) }

    /// Whether `history.pushState`/`replaceState` are the untouched originals.
    var historyIsUnhooked: Bool {
        bool("history.pushState === __fb.originalPushState && history.replaceState === __fb.originalReplaceState")
    }

    // MARK: - Simulated events

    /// Simulates an in-app (SPA) navigation the way these sites perform it: via `history.pushState`.
    func navigate(to path: String) throws {
        try evaluate("history.pushState({}, '', \(jsString(path)));")
    }

    /// Simulates the back/forward button.
    func popState(to path: String) throws {
        try evaluate("__fb.popState(\(jsString(path)));")
    }

    /// Simulates the user flipping a toggle in the popup, which writes to `browser.storage.local`.
    func setStorage(_ key: String, to value: Bool) throws {
        try evaluate("__fb.setStorage(\(jsString(key)), \(value));")
    }

    /// Dispatches a click on a same-site link to `path` and returns whether a listener called `preventDefault()`.
    @discardableResult
    func click(path: String) throws -> Bool {
        try evaluate("__fb.click(\(jsString(path)));").toBool()
    }

    // MARK: - Helpers

    @discardableResult
    private func evaluate(_ script: String) throws -> JSValue {
        pendingException = nil
        let result = context.evaluateScript(script)
        if let pendingException {
            throw HarnessError.javaScript(pendingException)
        }
        return result ?? JSValue(undefinedIn: context)
    }

    private func bool(_ expression: String) -> Bool {
        context.evaluateScript(expression).toBool()
    }

    private func strings(_ expression: String) -> [String] {
        context.evaluateScript(expression).toArray() as? [String] ?? []
    }

    private func jsString(_ value: String) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: [value])) ?? Data("[\"\"]".utf8)
        return String(decoding: data, as: UTF8.self) + "[0]"
    }

    /// Just enough of the browser/WebExtension surface for the content scripts to run.
    private static let fakeBrowserEnvironment = #"""
    var window = globalThis;

    __fb.replacedWith = [];
    __fb.assignedWith = [];
    __fb.storageListeners = [];
    __fb.documentListeners = [];
    __fb.windowListeners = [];
    __fb.intervals = [];
    __fb.observers = [];
    __fb.classes = new Set();

    if (typeof globalThis.queueMicrotask !== "function") {
        globalThis.queueMicrotask = (fn) => { Promise.resolve().then(fn); };
    }

    globalThis.location = {
        hostname: "www.example.com",
        get pathname() { return __fb.path; },
        get href() { return "https://www.example.com" + __fb.path; },
        replace(url) { __fb.replacedWith.push(url); __fb.path = url; },
        assign(url) { __fb.assignedWith.push(url); __fb.path = url; },
    };

    globalThis.history = {
        pushState(state, title, url) { if (url !== undefined) __fb.path = url; },
        replaceState(state, title, url) { if (url !== undefined) __fb.path = url; },
    };
    __fb.originalPushState = history.pushState;
    __fb.originalReplaceState = history.replaceState;

    globalThis.document = {
        documentElement: {
            classList: {
                add: (...names) => { names.forEach((name) => __fb.classes.add(name)); },
                remove: (...names) => { names.forEach((name) => __fb.classes.delete(name)); },
                contains: (name) => __fb.classes.has(name),
                toggle: (name, force = !__fb.classes.has(name)) => {
                    if (force) __fb.classes.add(name); else __fb.classes.delete(name);
                    return force;
                },
            },
        },
        addEventListener(type, fn) { __fb.documentListeners.push({ type, fn }); },
        removeEventListener(type, fn) {
            __fb.documentListeners = __fb.documentListeners.filter((l) => !(l.type === type && l.fn === fn));
        },
    };

    globalThis.addEventListener = (type, fn) => { __fb.windowListeners.push({ type, fn }); };
    globalThis.removeEventListener = (type, fn) => {
        __fb.windowListeners = __fb.windowListeners.filter((l) => !(l.type === type && l.fn === fn));
    };

    globalThis.MutationObserver = class {
        constructor(callback) { this.callback = callback; this.active = false; __fb.observers.push(this); }
        observe() { this.active = true; }
        disconnect() { this.active = false; }
    };

    globalThis.setInterval = (fn) => { __fb.intervals.push({ fn, active: true }); return __fb.intervals.length; };
    globalThis.clearInterval = (id) => { const timer = __fb.intervals[id - 1]; if (timer) timer.active = false; };

    globalThis.browser = {
        storage: {
            local: {
                get(defaults) { return Promise.resolve(Object.assign({}, defaults, __fb.storage)); },
            },
            onChanged: {
                addListener(fn) { __fb.storageListeners.push(fn); },
            },
        },
    };

    __fb.activeIntervalCount = () => __fb.intervals.filter((t) => t.active).length;
    __fb.activeObserverCount = () => __fb.observers.filter((o) => o.active).length;

    __fb.setStorage = (key, value) => {
        const oldValue = __fb.storage[key];
        __fb.storage[key] = value;
        __fb.storageListeners.forEach((fn) => fn({ [key]: { oldValue, newValue: value } }, "local"));
    };

    __fb.popState = (path) => {
        __fb.path = path;
        __fb.windowListeners.filter((l) => l.type === "popstate").forEach((l) => l.fn({}));
    };

    __fb.click = (path) => {
        const anchor = {
            hostname: location.hostname,
            pathname: path,
            getAttribute: (name) => (name === "href" ? path : null),
        };
        const event = {
            target: { closest: () => anchor },
            defaultPrevented: false,
            preventDefault() { this.defaultPrevented = true; },
            stopPropagation() {},
        };
        __fb.documentListeners.filter((l) => l.type === "click").forEach((l) => l.fn(event));
        return event.defaultPrevented;
    };
    """#
}
