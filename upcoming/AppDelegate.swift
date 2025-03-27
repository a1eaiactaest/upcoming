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
    
    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.updateMenuBar()
                } else {
                    self.statusBarItem?.button?.title = "No Calendar Access"
                }
            }
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateMenuBar()
        }
    }

    func updateMenuBar() {
        guard let nextEvent = fetchNextEvent() else {
            statusBarItem?.button?.title = "No upcoming events"
            updateMenuItems(with: nil)
            return
        }
        
        let timeLeft = timeUntilEvent(nextEvent)
        let title = "\(nextEvent.title) in \(timeLeft)"
        statusBarItem?.button?.title = title
    }
    
    func fetchNextEvent() -> EKEvent? {
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let predicate = eventStore.predicateForEvents(withStart: now, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
            .filter{ !$0.isAllDay }
            .sorted{ $0.startDate < $1.startDate }
        return events.first
        
    }

    @objc func statusBarButtonClicked(_ sender : NSStatusBarButton) {
        print("menu bar item clicked edit")
        // TODO: handling logic here
    }

    private func setupMyApp() {
        // TODO: Add any intialization steps here.
        print("Application started up!")
    }
}
