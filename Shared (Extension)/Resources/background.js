async function syncFromNative() {
    try {
        console.log("Syncing...");
        
        const prefs = await browser.runtime.sendNativeMessage("com.buildthestack.feedblocker", { name: "getPreferences" });
        await browser.storage.local.set(prefs);
        return prefs;
    } catch (e) {
        console.warn("Native sync failed", e);
        // Fallback to reading from storage if native sync fails
        return browser.storage.local.get(null);
    }
}

async function setPreference(site, enabled) {
    // Write to storage immediately so UI feels responsive
    await browser.storage.local.set({ [`enabled_${site}`]: enabled });
    // Persist to native App Group
    try {
        await browser.runtime.sendNativeMessage("com.buildthestack.feedblocker", {
            name: "setPreference",
            site,
            enabled
        });
    } catch (e) {
        console.warn("Failed to persist to native:", e);
    }
}

// Sync whenever a tab finishes loading
browser.tabs.onUpdated.addListener((tabId, changeInfo) => {
    if (changeInfo.status === "complete") syncFromNative();
});

// Sync when the user switches tabs
browser.tabs.onActivated.addListener(syncFromNative);

// Sync periodically to catch changes from the native app
setInterval(syncFromNative, 2000); // Poll every 2 seconds

// Initial sync when extension loads
syncFromNative();

// Handle messages from popup and content scripts
browser.runtime.onMessage.addListener((message) => {
    if (message.name === "getPreferences") return syncFromNative();
    if (message.name === "setPreference") return setPreference(message.site, message.enabled);
});
