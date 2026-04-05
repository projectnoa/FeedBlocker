//
//  Sites.swift
//  FeedBlocker
//
//  Created by Juan Reyes on 4/5/26.
//

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
