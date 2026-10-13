// content/blocker.js
// Shared engine for the per-site content scripts. It is listed before each site script in
// manifest.json, and each site script calls `FeedBlocker.start(...)` with its own rules.
globalThis.FeedBlocker ??= (() => {
    const HOME = "/";

    /** True when `path` is `prefix` itself or anything below it ("/reels", "/reels/abc"), but not "/reelsfan". */
    const isUnder = (path, prefix) => path === prefix || path.startsWith(prefix + "/");

    /**
     * @param {object} options
     * @param {string} options.storageKey - `browser.storage.local` key holding the on/off preference.
     * @param {(path: string) => boolean} options.isFeedPage - Pages that get the `no-feed` class.
     * @param {string[]} [options.blockedPrefixes] - Routes redirected home (and whose links are intercepted).
     * @param {string[]} [options.alwaysOnClasses] - Classes applied on every page while enabled.
     */
    function start({ storageKey, isFeedPage, blockedPrefixes = [], alwaysOnClasses = [] }) {
        const root = document.documentElement;
        const isBlocked = (path) => blockedPrefixes.some((prefix) => isUnder(path, prefix));

        let enabled = false;
        let teardown = null;

        // Only touch the attribute when the value actually changes. classList.add() on a class
        // that's already present still counts as an attribute mutation, which would make the
        // class observer below re-trigger itself forever.
        const setClass = (name, on) => {
            if (root.classList.contains(name) !== on) root.classList.toggle(name, on);
        };

        const applyClasses = () => {
            setClass("no-feed", isFeedPage(location.pathname));
            for (const name of alwaysOnClasses) setClass(name, true);
        };

        const removeClasses = () => {
            for (const name of ["no-feed", ...alwaysOnClasses]) setClass(name, false);
        };

        const apply = () => {
            if (!enabled) return;

            if (isBlocked(location.pathname)) {
                // replace avoids polluting history with blocked routes
                location.replace(HOME);
                return;
            }

            applyClasses();
        };

        function enable() {
            if (enabled) return;
            enabled = true;

            // Handle SPA navigation by hooking history methods
            const { pushState, replaceState } = history;

            history.pushState = function (...args) {
                const ret = pushState.apply(this, args);
                queueMicrotask(apply);
                return ret;
            };

            history.replaceState = function (...args) {
                const ret = replaceState.apply(this, args);
                queueMicrotask(apply);
                return ret;
            };

            // Intercept clicks on blocked links before the site's own handler navigates
            const onClick = (e) => {
                const link = e.target?.closest?.("a[href]");
                if (!link || link.hostname !== location.hostname || !isBlocked(link.pathname)) return;

                e.preventDefault();
                e.stopPropagation();
                location.assign(HOME);
            };

            document.addEventListener("click", onClick, true);
            addEventListener("popstate", apply, { passive: true });

            // Safety net for frameworks that update the URL without history events
            let last = location.href;
            const intervalId = setInterval(() => {
                if (location.href === last) return;
                last = location.href;
                apply();
            }, 500);

            // Re-apply if the site rewrites <html class="..."> (YouTube does this while booting)
            const observer = new MutationObserver(applyClasses);
            observer.observe(root, { attributes: true, attributeFilter: ["class"] });

            teardown = () => {
                history.pushState = pushState;
                history.replaceState = replaceState;
                document.removeEventListener("click", onClick, true);
                removeEventListener("popstate", apply);
                clearInterval(intervalId);
                observer.disconnect();
            };

            apply();
        }

        function disable() {
            enabled = false;
            teardown?.();
            teardown = null;
            removeClasses();
        }

        // Hide right away at document_start so the feed doesn't flash while the preference
        // loads. Redirects wait for the preference so a disabled site is never navigated away.
        applyClasses();

        browser.storage.local.get({ [storageKey]: true }).then((prefs) => {
            if (prefs[storageKey]) enable();
            else disable();
        });

        browser.storage.onChanged.addListener((changes, area) => {
            if (area !== "local" || !(storageKey in changes)) return;

            // A removed key falls back to the default (enabled)
            if (changes[storageKey].newValue !== false) enable();
            else disable();
        });
    }

    return { start };
})();
