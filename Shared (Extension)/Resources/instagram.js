// content/instagram.js
(() => {
    function cleanup() {
        document.documentElement.classList.remove("no-feed");
        // cancel any intervals/listeners your init() sets up
    }

    // Initial state on page load
    browser.storage.local.get({ enabled_instagram: true }).then(({ enabled_instagram }) => {
        if (enabled_instagram) init();
    });

    // React to changes while the page is open
    browser.storage.onChanged.addListener((changes) => {
        if (!("enabled_instagram" in changes)) return;
        if (changes.enabled_instagram.newValue) init();
        else cleanup();
    });
    
    function init() {
        const HOME = "/";
        
        const isHome = () => location.pathname === "/";
        
        const isReels = () =>
        location.pathname === "/reel" ||
        location.pathname === "/reels" ||
        location.pathname.startsWith("/reel/") ||
        location.pathname.startsWith("/reels/");
        
        const isExplore = () =>
        location.pathname === "/explore" ||
        location.pathname.startsWith("/explore/");
        
        const apply = () => {
            // Block routes
            if (isReels() || isExplore()) {
                // replace avoids polluting history with blocked routes
                location.replace(HOME);
                
                return;
            }
            
            // Hide the feed
            if (isHome()) {
                document.documentElement.classList.add("no-feed");
            } else {
                document.documentElement.classList.remove("no-feed");
            }
        };
        
        // Run once ASAP
        apply();
        
        // Handle SPA navigation
        const hookHistory = () => {
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
            
            window.addEventListener("popstate", apply, { passive: true });
        };
        
        hookHistory();
        
        // Intercept clicks on Reels links (before handler)
        document.addEventListener("click", (e) => {
            const a = e.target.closest("a[href]");
            
            if (!a) return;
            
            const href = a.getAttribute("href") || "";
            
            if (href.startsWith("/reels") || href.startsWith("/reel/")) {
                e.preventDefault();
                e.stopPropagation();
                
                location.assign(HOME);
            }
        }, true);
        
        // Lightweight “safety net” for occasional edge cases
        // (some frameworks update location without history events)
        let last = location.href;
        
        setInterval(() => {
            if (location.href !== last) {
                last = location.href;
                
                apply();
            }
        }, 500);
    }
})();
