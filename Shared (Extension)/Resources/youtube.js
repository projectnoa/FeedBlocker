// content/youtube.js
(() => {
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
})();

