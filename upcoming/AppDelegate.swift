//
//  AppDelegate.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 27/03/2025.
//


import Foundation
import AppKit
import EventKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var eventStore = EKEventStore()
    var timer: Timer?
    
    // swiftlint: disable line_length
    func applicationDidFinishLaunching(_ notification: Notification) {
        // main loop i guess
        setupMenuBar()
        requestCalendarAccess()
        startTimer()
    }
    
    func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.title = "Loading.."
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(
            title: "Loading",
            action: nil,
            keyEquivalent: "")
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Preferences",
            action: #selector(openPreferences),
            keyEquivalent: ",")
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        
        statusBarItem?.menu = menu

    }
    
    func requestCalendarAccess(){}
    
    func startTimer(){}
    
    @objc func statusBarButtonClicked(_ sender : NSStatusBarButton) {
        print("menu bar item clicked edit")
        // TODO: handling logic here
    }

    private func setupMyApp() {
        // TODO: Add any intialization steps here.
        print("Application started up!")
    }
}
