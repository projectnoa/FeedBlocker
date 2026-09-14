// content/youtube.js
(() => {
    let observer = null;
    let intervalId = null;
    let historyHooked = false;
    let originalPushState = null;
    let originalReplaceState = null;
    let popstateHandler = null;
    let isEnabled = false;
    
    function cleanup() {
        isEnabled = false;
        
        document.documentElement.classList.remove("no-feed");
        
        // Clean up observer
        if (observer) {
            observer.disconnect();
            
            observer = null;
        }
        
        // Clean up interval
        if (intervalId) {
            clearInterval(intervalId);
            
            intervalId = null;
        }
        
        // Restore original history methods
        if (historyHooked && originalPushState && originalReplaceState) {
            history.pushState = originalPushState;
            history.replaceState = originalReplaceState;
            
            if (popstateHandler)
                window.removeEventListener("popstate", popstateHandler);
            
            historyHooked = false;
        }
    }

    // Initial state on page load
    browser.storage.local.get({ enabled_youtube: true }).then(({ enabled_youtube }) => {
        if (enabled_youtube) init();
        else cleanup(); // Ensure clean state if disabled
    });

    // React to changes while the page is open
    browser.storage.onChanged.addListener((changes) => {
        if (!("enabled_youtube" in changes)) return;
        
        if (changes.enabled_youtube.newValue)
            init();
        else
            cleanup();
    });
    
    function init() {
        // Prevent duplicate initialization
        if (isEnabled) return;
        
        isEnabled = true;
        
        const isHome = () => location.pathname === "/" || location.pathname === "";
        
        const apply = () => {
            // Only apply if still enabled
            if (!isEnabled) return;
            
            // Hide the feed on home page
            if (isHome()) {
                document.documentElement.classList.add("no-feed");
            } else {
                document.documentElement.classList.remove("no-feed");
            }
        };
        
        // Run once ASAP
        apply();
        
        // Handle SPA navigation by hooking history methods
        if (!historyHooked) {
            originalPushState = history.pushState;
            originalReplaceState = history.replaceState;
            
            history.pushState = function (...args) {
                const ret = originalPushState.apply(this, args);
                
                if (isEnabled) queueMicrotask(apply);
                
                return ret;
            };
            
            history.replaceState = function (...args) {
                const ret = originalReplaceState.apply(this, args);
                
                if (isEnabled) queueMicrotask(apply);
                
                return ret;
            };
            
            popstateHandler = () => {
                if (isEnabled) apply();
            };
            
            window.addEventListener("popstate", popstateHandler, { passive: true });
            
            historyHooked = true;
        }
        
        // Re-run when the DOM changes (YouTube re-renders a lot)
        observer = new MutationObserver(() => {
            if (isEnabled) apply();
        });
        
        observer.observe(document.documentElement, { childList: true, subtree: true });
        
        // Safety net for occasional edge cases
        let last = location.href;
        intervalId = setInterval(() => {
            if (!isEnabled) return;
            if (location.href !== last) {
                last = location.href;
                apply();
            }
        }, 500);
    }
})();

