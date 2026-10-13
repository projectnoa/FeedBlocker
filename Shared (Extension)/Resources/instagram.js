// content/instagram.js
FeedBlocker.start({
    storageKey: "enabled_instagram",
    isFeedPage: (path) => path === "/",
    blockedPrefixes: ["/reel", "/reels", "/explore"],
});
