console.log("Feed blocker starts!", browser);

// Sync from native first, then reflect current state
browser.runtime.sendMessage({ name: "getPreferences" }).then((prefs) => {
    for (const site of ["facebook", "instagram", "youtube"]) {
        const toggle = document.getElementById(site);
        if (toggle) toggle.checked = prefs?.[`enabled_${site}`] ?? true;
    }
});

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
    document.getElementById(site)?.addEventListener("change", (e) => {
        browser.runtime.sendMessage({
            name: "setPreference",
            site,
            enabled: e.target.checked
        });
    });
}

//const toggleFacebook = document.getElementById("toggleFacebook");
//
//// Reflect the current stored state when the popup opens
//browser.storage.local.get({ enabled_facebook: true }).then(({ enabled_facebook }) => {
//    toggleFacebook.checked = enabled_facebook;
//});
//
//// Persist the new state whenever the user flips the switch
//toggleFacebook.addEventListener("change", () => {
//    browser.storage.local.set({ enabled_facebook: toggleFacebook.checked });
//});
//
//const toggleInstagram = document.getElementById("toggleInstagram");
//
//// Reflect the current stored state when the popup opens
//browser.storage.local.get({ enabled_instagram: true }).then(({ enabled_instagram }) => {
//    toggleInstagram.checked = enabled_instagram;
//});
//
//// Persist the new state whenever the user flips the switch
//toggleInstagram.addEventListener("change", () => {
//    browser.storage.local.set({ enabled_instagram: toggleInstagram.checked });
//});
//
//const toggleYouTube = document.getElementById("toggleYouTube");
//
//// Reflect the current stored state when the popup opens
//browser.storage.local.get({ enabled_youtube: true }).then(({ enabled_youtube }) => {
//    toggleYouTube.checked = enabled_youtube;
//});
//
//// Persist the new state whenever the user flips the switch
//toggleYouTube.addEventListener("change", () => {
//    browser.storage.local.set({ enabled_youtube: toggleYouTube.checked });
//});
