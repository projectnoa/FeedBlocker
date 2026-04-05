//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by Juan Reyes on 1/17/26.
//

import SafariServices
import os.log

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

    var storageKey: String { "enabled_\(rawValue)" }
}

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    let defaults = UserDefaults(suiteName: "group.com.buildthestack.feedblocker.prefs")!

    func beginRequest(with context: NSExtensionContext) {
        guard
            let item = context.inputItems.first as? NSExtensionItem,
            let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any]
        else {
            context.completeRequest(returningItems: [],
                                    completionHandler: nil)
            return
        }

        switch message["name"] as? String {
        case "getPreferences":
            var prefs: [String: Bool] = [:]
            
            for site in Site.allCases {
                prefs[site.storageKey] = defaults.object(forKey: site.storageKey) as? Bool ?? true
            }
            
            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: prefs]
            
            context.completeRequest(returningItems: [response],
                                    completionHandler: nil)

        case "setPreference":
            if let site = message["site"] as? String,
               let enabled = message["enabled"] as? Bool {
                defaults.set(enabled, forKey: "enabled_\(site)")
            }
            
            context.completeRequest(returningItems: [],
                                    completionHandler: nil)

        default:
            context.completeRequest(returningItems: [],
                                    completionHandler: nil)
        }
        
        
//        let request = context.inputItems.first as? NSExtensionItem
//
//        let profile: UUID?
//        
//        if #available(iOS 17.0, macOS 14.0, *) {
//            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
//        } else {
//            profile = request?.userInfo?["profile"] as? UUID
//        }
//
//        let message: Any?
//        
//        if #available(iOS 15.0, macOS 11.0, *) {
//            message = request?.userInfo?[SFExtensionMessageKey]
//        } else {
//            message = request?.userInfo?["message"]
//        }
//
//        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)", String(describing: message), profile?.uuidString ?? "none")
//
//        let response = NSExtensionItem()
//        
//        if #available(iOS 15.0, macOS 11.0, *) {
//            response.userInfo = [ SFExtensionMessageKey: [ "echo": message ] ]
//        } else {
//            response.userInfo = [ "message": [ "echo": message ] ]
//        }
//
//        context.completeRequest(returningItems: [ response ],
//                                completionHandler: nil)
    }

}
