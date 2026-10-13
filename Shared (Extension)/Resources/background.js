// browser.storage.local is the source of truth for preferences: the popup writes it and the
// content scripts read it directly. This mirrors each change into the App Group via the native
// handler so the containing app can read the same values.
browser.storage.onChanged.addListener((changes, area) => {
    if (area !== "local") return;

    for (const [key, { newValue }] of Object.entries(changes)) {
        if (!key.startsWith("enabled_")) continue;

        browser.runtime.sendNativeMessage("com.buildthestack.feedblocker", {
            name: "setPreference",
            site: key.slice("enabled_".length),
            enabled: newValue !== false
        }).catch((e) => console.warn("Failed to persist to native:", e));
    }
});
