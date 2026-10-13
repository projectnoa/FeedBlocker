//
//  Sites.swift
//  FeedBlocker
//
//  Created by Juan Reyes on 4/5/26.
//

import Foundation

enum Site: String, CaseIterable {
    case facebook  = "facebook"
    case instagram = "instagram"
    case youtube   = "youtube"

    var displayName: String {
        switch self {
        case .facebook:  return "Facebook"
        case .instagram: return "Instagram"
        case .youtube:   return "YouTube"
        }
    }

    /// Matches the `browser.storage.local` key used by the extension's JavaScript.
    var storageKey: String { "enabled_\(rawValue)" }
}

/// Per-site preferences shared between the app and the extension through the App Group.
enum SitePreferences {
    /// Must match `com.apple.security.application-groups` in every target's entitlements.
    static let appGroup = "group.com.buildthestack.feedblocker.pref"

    /// Falls back to standard defaults if the App Group container isn't available.
    static let defaults = UserDefaults(suiteName: appGroup) ?? .standard

    static func isEnabled(_ site: Site) -> Bool {
        defaults.object(forKey: site.storageKey) as? Bool ?? true
    }

    static func setEnabled(_ site: Site, enabled: Bool) {
        defaults.set(enabled, forKey: site.storageKey)
    }
}
