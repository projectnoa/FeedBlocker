//
//  ViewController.swift
//  Shared (App)
//
//  Created by Juan Reyes on 1/17/26.
//

import WebKit

#if os(iOS)
import UIKit
typealias PlatformViewController = UIViewController
typealias PlatformStackView = UIStackView
#elseif os(macOS)
import Cocoa
import SafariServices
typealias PlatformViewController = NSViewController
typealias PlatformStackView = NSStackView
#endif

let extensionBundleIdentifier = "com.buildthestack.FeedBlocker.Extension"

class ViewController: PlatformViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildUI()
    }
    
    deinit {
        
    }

    private func buildUI() {
        // DO NOTHING
    }
    
    private func reloadExtension() {
        #if os(iOS)
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: extensionBundleIdentifier)
        #elseif os(macOS)
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { state, error in
            // Trigger a reload by dispatching to the extension
            guard error == nil else { return }
        }
        #endif
    }
}

struct SitePreferences {
    static let defaults = UserDefaults(suiteName: "group.com.buildthestack.feedblocker.prefs")!

    static func isEnabled(_ site: Site) -> Bool {
        defaults.object(forKey: site.storageKey) as? Bool ?? true
    }

    static func setEnabled(_ site: Site, enabled: Bool) {
        defaults.set(enabled, forKey: site.storageKey)
    }
}
