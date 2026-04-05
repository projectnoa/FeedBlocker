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
typealias PlatformSwitch = UISwitch
typealias PlatformStackView = UIStackView
typealias PlatformView = UIView
#elseif os(macOS)
import Cocoa
import SafariServices
typealias PlatformViewController = NSViewController
typealias PlatformSwitch = NSSwitch
typealias PlatformStackView = NSStackView
typealias PlatformView = NSView
#endif

let extensionBundleIdentifier = "com.buildthestack.FeedBlocker.Extension"

class ViewController: PlatformViewController {

    @IBOutlet private var stackView: PlatformStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildUI()
    }

    private func buildUI() {
        for site in Site.allCases {
            stackView.addArrangedSubview(makeRow(for: site))
        }
    }

    private func makeRow(for site: Site) -> PlatformView {
        let enabled = SitePreferences.isEnabled(site)

        #if os(iOS)
        let row = UIView()
        let label = UILabel()
        label.text = site.displayName
        label.font = .systemFont(ofSize: 17)

        let toggle = UISwitch()
        toggle.isOn = enabled
        toggle.tag = Site.allCases.firstIndex(of: site)!
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)

        for v in [label, toggle] {
            v.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(v)
        }
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return row
        #elseif os(macOS)
        let row = NSStackView()
        row.orientation = .horizontal

        let label = NSTextField(labelWithString: site.displayName)

        let toggle = NSSwitch()
        toggle.state = enabled ? .on : .off
        toggle.tag = Site.allCases.firstIndex(of: site)!
        toggle.target = self
        toggle.action = #selector(toggleChanged(_:))

        row.addArrangedSubview(label)
        row.addArrangedSubview(toggle)
        
        return row
        #endif
    }

    @objc private func toggleChanged(_ sender: PlatformSwitch) {
        let site = Site.allCases[sender.tag]

        #if os(iOS)
        let enabled = sender.isOn
        #elseif os(macOS)
        let enabled = sender.state == .on
        #endif

        SitePreferences.setEnabled(site, enabled: enabled)
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
