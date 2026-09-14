console.log("Feed blocker starts!", browser);

// Initialize popup state
async function initializePopup() {
    // First, sync from native to ensure we have the latest preferences
    const prefs = await browser.runtime.sendMessage({ name: "getPreferences" });
    
    // Then set all toggles based on the synced preferences
    for (const site of ["facebook", "instagram", "youtube"]) {
        const toggle = document.getElementById(site);
        if (toggle) {
            toggle.checked = prefs?.[`enabled_${site}`] ?? true;
        }
    }
}

// Initialize when popup opens
initializePopup();

// Keep toggles updated if storage changes while popup is open
browser.storage.onChanged.addListener((changes) => {
    for (const [key, { newValue }] of Object.entries(changes)) {
        if (!key.startsWith("enabled_")) continue;
        const site = key.replace("enabled_", "");
        const toggle = document.getElementById(site);
        if (toggle) toggle.checked = newValue;
    }
});

// Write changes back through the background script
for (const site of ["facebook", "instagram", "youtube"]) {
    const toggle = document.getElementById(site);
    
    toggle?.addEventListener("change", (e) => {
        browser.runtime.sendMessage({
            name: "setPreference",
            site,
            enabled: e.target.checked
        });
    });
}
