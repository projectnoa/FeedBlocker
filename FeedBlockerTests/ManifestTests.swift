//
//  ManifestTests.swift
//  FeedBlockerTests
//

import Foundation
import Testing

/// Guards against the extension's resource files drifting out of sync with each other.
@Suite("Extension manifest")
struct ManifestTests {
    private struct Manifest: Decodable {
        struct ContentScript: Decodable {
            let matches: [String]
            let js: [String]?
            let css: [String]?
        }

        struct Background: Decodable {
            let scripts: [String]?
            let persistent: Bool?
        }

        let background: Background?
        let content_scripts: [ContentScript]
        let host_permissions: [String]
    }

    private let resources = ContentScriptHarness.resourcesURL

    private func loadManifest() throws -> Manifest {
        let data = try Data(contentsOf: resources.appending(path: "manifest.json"))
        return try JSONDecoder().decode(Manifest.self, from: data)
    }

    @Test func everyContentScriptFileExists() throws {
        let manifest = try loadManifest()
        let files = manifest.content_scripts.flatMap { ($0.js ?? []) + ($0.css ?? []) }

        #expect(!files.isEmpty)
        for file in files {
            #expect(FileManager.default.fileExists(atPath: resources.appending(path: file).path(percentEncoded: false)), "Missing \(file)")
        }
    }

    /// App Store validation rejects iOS builds whose script-based background page isn't explicitly non-persistent.
    @Test func backgroundScriptIsNonPersistent() throws {
        let background = try #require(try loadManifest().background)

        if background.scripts != nil {
            #expect(background.persistent == false)
        }
    }

    /// Each site script calls `FeedBlocker.start`, so the shared engine must be listed first.
    @Test func sharedEngineLoadsBeforeEverySiteScript() throws {
        let manifest = try loadManifest()

        for contentScript in manifest.content_scripts {
            #expect(contentScript.js?.first == "blocker.js", "blocker.js must come first in \(contentScript.matches)")
        }
    }

    @Test func everyContentScriptMatchHasHostPermission() throws {
        let manifest = try loadManifest()

        for pattern in manifest.content_scripts.flatMap(\.matches) {
            #expect(manifest.host_permissions.contains(pattern), "No host permission for \(pattern)")
        }
    }

    /// The popup toggles write `enabled_<checkbox id>`; each site's script must read that same key.
    @Test(arguments: ["facebook", "instagram", "youtube"])
    func popupToggleMatchesContentScriptKey(site: String) throws {
        let popup = try String(contentsOf: resources.appending(path: "popup.html"), encoding: .utf8)
        let script = try String(contentsOf: resources.appending(path: "\(site).js"), encoding: .utf8)

        #expect(popup.contains("id=\"\(site)\""))
        #expect(script.contains("enabled_\(site)"))
    }
}
