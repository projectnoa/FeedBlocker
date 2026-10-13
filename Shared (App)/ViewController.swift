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
}
