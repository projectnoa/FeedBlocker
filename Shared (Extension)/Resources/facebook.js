// content/facebook.js
FeedBlocker.start({
    storageKey: "enabled_facebook",
    isFeedPage: (path) => path === "/",
    blockedPrefixes: ["/reel", "/reels", "/watch"],
});
