//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by Juan Reyes on 1/17/26.
//

import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        defer {
            context.completeRequest(returningItems: [], completionHandler: nil)
        }

        guard
            let item = context.inputItems.first as? NSExtensionItem,
            let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any]
        else { return }

        switch message["name"] as? String {
        case "setPreference":
            guard
                let rawSite = message["site"] as? String,
                let site = Site(rawValue: rawSite),
                let enabled = message["enabled"] as? Bool
            else {
                os_log(.error, "Ignoring malformed setPreference message: %@", String(describing: message))
                return
            }

            SitePreferences.setEnabled(site, enabled: enabled)

        default:
            break
        }
    }
}
