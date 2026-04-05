// content/youtube.js
(() => {
    function cleanup() {
        document.documentElement.classList.remove("no-feed");
        // cancel any intervals/listeners your init() sets up
    }

    // Initial state on page load
    browser.storage.local.get({ enabled_youtube: true }).then(({ enabled_youtube }) => {
        if (enabled_youtube) init();
    });

    // React to changes while the page is open
    browser.storage.onChanged.addListener((changes) => {
        if (!("enabled_youtube" in changes)) return;
        if (changes.enabled_youtube.newValue) init();
        else cleanup();
    });
    
    function init() {
        const apply = () => {
            // Example: if you only want to kill the home feed:
            
            if (location.pathname === "/") {
                // CSS already hides it; this is where you'd do JS-only removals if needed.
            }
        };
        
        // Run now
        apply();
        
        // Re-run when the DOM changes (YouTube re-renders a lot)
        const obs = new MutationObserver(() => apply());
        
        obs.observe(document.documentElement, { childList: true, subtree: true });
        
        // Catch SPA URL changes
        let last = location.href;
        
        setInterval(() => {
            if (location.href !== last) {
                last = location.href;
                
                apply();
            }
        }, 500);
    }
})();

