const SITES = ["facebook", "instagram", "youtube"];
const keyFor = (site) => `enabled_${site}`;

// Initialize popup state (every site defaults to enabled)
async function initializePopup() {
    const defaults = Object.fromEntries(SITES.map((site) => [keyFor(site), true]));
    const prefs = await browser.storage.local.get(defaults);

    for (const site of SITES) {
        const toggle = document.getElementById(site);
        if (toggle) toggle.checked = prefs[keyFor(site)] !== false;
    }
}

// Initialize when popup opens
initializePopup();

// Keep toggles updated if storage changes while popup is open
browser.storage.onChanged.addListener((changes, area) => {
    if (area !== "local") return;

    for (const site of SITES) {
        const change = changes[keyFor(site)];
        const toggle = document.getElementById(site);
        if (change && toggle) toggle.checked = change.newValue !== false;
    }
});

// Write changes to storage; content scripts react via storage.onChanged
for (const site of SITES) {
    document.getElementById(site)?.addEventListener("change", (e) => {
        browser.storage.local.set({ [keyFor(site)]: e.target.checked });
    });
}
