async function syncFromNative() {
    try {
        console.log("Syncing...", e);
        
        const prefs = await browser.runtime.sendNativeMessage("com.buildthestack.feedblocker", { name: "getPreferences" });
        await browser.storage.local.set(prefs);
        return prefs;
    } catch (e) {
        console.warn("Native sync failed", e);
    }
}

async function setPreference(site, enabled) {
    // Write to storage immediately so UI feels responsive
    await browser.storage.local.set({ [`enabled_${site}`]: enabled });
    // Persist to native App Group
    await browser.runtime.sendNativeMessage("com.buildthestack.feedblocker", {
        name: "setPreference",
        site,
        enabled
    });
}

// Sync whenever a tab finishes loading
browser.tabs.onUpdated.addListener((tabId, changeInfo) => {
    if (changeInfo.status === "complete") syncFromNative();
});

// Sync when the user switches tabs
browser.tabs.onActivated.addListener(syncFromNative);

// Handle messages from popup and content scripts
browser.runtime.onMessage.addListener((message) => {
    if (message.name === "getPreferences") return syncFromNative();
    if (message.name === "setPreference") return setPreference(message.site, message.enabled);
});
