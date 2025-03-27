//
//  AppDelegate.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 27/03/2025.
//


import Foundation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarItem: NSStatusItem?
    
    // swiftlint: disable line_length
    func applicationDidFinishLaunching(_ notification: Notification) {
        // main loop i guess
        statusBarItem = NSStatusBar.system.statusItem(withLength:
                                                        NSStatusItem.variableLength)
        if let button = statusBarItem?.button {
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.title = "open window"
        }
    }
    
    @objc func statusBarButtonClicked(_ sender : NSStatusBarButton) {
        print("menu bar item clicked")
        // TODO: handling logic here
    }

    private func setupMyApp() {
        // TODO: Add any intialization steps here.
        print("Application started up!")
    }
}
