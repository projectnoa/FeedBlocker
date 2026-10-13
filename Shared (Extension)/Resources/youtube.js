// content/youtube.js
// `no-feed` hides the home feed; `no-recs` hides Shorts and recommendations on every page.
FeedBlocker.start({
    storageKey: "enabled_youtube",
    isFeedPage: (path) => path === "/",
    blockedPrefixes: ["/shorts"],
    alwaysOnClasses: ["no-recs"],
});
