//
//  AppDelegate.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 27/03/2025.
//


import Foundation
import AppKit
import EventKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var calendarManager = CalendarManager()
    private var cancellables = Set<AnyCancellable>()
    
    var statusBarItem: NSStatusItem!
    var eventStore = EKEventStore()
    var timer: Timer?
    var preferences = Preferences()
    
    // swiftlint: disable line_length
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupCalendarObservation()
        setupMenuBar()
        Task {
            // Request calendar access immediately on launch
            try? await requestCalendarAccess()
            try? await calendarManager.loadCalendars()
            startTimer()
        }
    }
    
    private func setupCalendarObservation() {
        /*
        calendarManager.$calendars
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBar()
            }
            .store(in: &cancellables)
         */
        /*
        NotificationCenter.default.publisher(for: .calendarDataDidChange)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        self?.updateMenuBar()
                    }
                    .store(in: &cancellables)
         */
        NotificationCenter.default.addObserver(
            forName: .calendarDataDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let calendars = notification.object as? [EKCalendar] else { return }
            self?.handleNewCalendars(calendars)
        }
    }
    
    private func handleNewCalendars(_ calendars: [EKCalendar]) {
        let validIds = calendars.map { $0.calendarIdentifier }
        preferences.selectedCalendarIds = preferences.selectedCalendarIds.filter {
            validIds.contains($0)
        }
        
        updateMenuBar()
        
        if let preferencesWindow = NSApp.windows.first(where: { $0.title == "Preferences"}) {
            preferencesWindow.contentView?.needsDisplay = true
            if let hostingView = preferencesWindow.contentView as? NSHostingView<PreferencesView> {
                let newView = PreferencesView()
                hostingView.rootView = newView
                let hosting = NSHostingView(rootView: newView
                    .environmentObject(preferences)
                    .environmentObject(calendarManager))
                preferencesWindow.contentView = hosting
            }
        }
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
    
    private func requestCalendarAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined, .restricted, .denied:
            // Always request access if not authorized
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                if !granted {
                    showErrorAlert(
                        title: "Calendar Access Required",
                        message: "This app requires calendar access to function. Please enable it in System Settings > Privacy & Security > Calendars"
                    )
                }
                return granted
            } catch {
                showErrorAlert(
                    title: "Calendar Access Error",
                    message: "Could not access your calendars: \(error.localizedDescription)"
                )
                return false
            }
        case .authorized, .fullAccess:
            return true
        @unknown default:
            return false
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
            statusBarItem?.button?.image = nil
            updateMenuItems(with: nil)
            return
        }

        let imageWidth = 3
        let imageHeight = 16

        let color = nextEvent.calendar.color
        let image = NSImage(size: NSSize(width: imageWidth, height: imageHeight), flipped: false) { rect in
            let path = NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1)
            color?.setFill()
            path.fill()
            return true
        }
        
        let timeLeft = timeUntilEvent(nextEvent)
        let title = "\(nextEvent.title!) \(timeLeft)"
        
        if let button = statusBarItem?.button {
            button.image = image
            button.image?.size = NSSize(width: imageWidth, height: imageHeight)
            button.imagePosition = .imageLeft
            button.title = title
        }
        
        updateMenuItems(with: nextEvent)
    }

    func fetchNextEvent() -> EKEvent? {
        let calendars = calendarManager.filteredCalendars(selectedIDs: preferences.selectedCalendarIds)
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        
        let predicate = calendarManager.eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: calendars
        )
        
        let events = calendarManager.eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
        
        // First check for ongoing events
        if let currentEvent = events.first(where: { 
            $0.startDate <= now && $0.endDate > now 
        }) {
            return currentEvent
        }
        
        // If no ongoing events, return the next upcoming event
        return events.first
    }

    func timeUntilEvent(_ event: EKEvent) -> String {
        let now = Date()
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        
        // If event is ongoing, show time until it ends
        if event.startDate <= now && event.endDate > now {
            return ((formatter.string(from: now, to: event.endDate) ?? "") + "left")
        }
        
        // Otherwise show time until event starts
        return "in " + (formatter.string(from: now, to: event.startDate) ?? "")
    }

    func updateMenuItems(with event: EKEvent?) {
        guard let menu = statusBarItem.menu else { return }
        
        // Clear existing dynamic items (keep the last 3 static items)
        while menu.items.count > 3 {
            menu.removeItem(at: 0)
        }
        
        if let event = event {
            let titleItem = NSMenuItem(
                title: event.title,
                action: nil,
                keyEquivalent: ""
            )
            menu.insertItem(titleItem, at: 1)
            
            let timeItem = NSMenuItem(
                title: "\(event.startDate.formatted()) - \(event.endDate.formatted())",
                action: nil,
                keyEquivalent: ""
            )
            menu.insertItem(timeItem, at: 2)
            
            let locationItem = NSMenuItem(
                title: event.location ?? "No location",
                action: nil,
                keyEquivalent: ""
            )
            menu.insertItem(locationItem, at: 3)
            
            let skipItem = NSMenuItem(
                title: "Skip >>",
                action: #selector(skipEvent), // TODO: implem
                keyEquivalent: ""
            )
            skipItem.representedObject = event
            menu.insertItem(locationItem, at: 4)
            
            let noEventsItem = NSMenuItem( // TODO: think of something creative
                title: "no upcoming events",
                action: nil,
                keyEquivalent: ""
            )
            menu.insertItem(noEventsItem, at: 0)
            menu.insertItem(NSMenuItem.separator(), at: 1)
        }
    }
    
    @objc func skipEvent(_ sender: NSMenuItem) {
        guard let event = sender.representedObject as? EKEvent else { return }
        
        if preferences.skipConfirmationDisabled {
            performEventDeletion(event)
            return
        }
        
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to remove this event?"
        alert.informativeText = "This action cannot be undone. Event will be permanently removed from your calendar."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Dont't ask me again"
        
        let response = alert.runModal()
        
        if alert.suppressionButton?.state == .on {
            preferences.skipConfirmationDisabled = true
        }
        if response == .alertFirstButtonReturn {
            performEventDeletion(event)
        }
    }
    
    private func performEventDeletion(_ event: EKEvent) {
        do {
            try eventStore.remove(event, span: .thisEvent)
            updateMenuBar()
        } catch {
            showErrorAlert(
                title: "Failed to Remove Event",
                message: "Could not remove event \(error.localizedDescription)"
            )
        }
    }

    @objc func openPreferences() {
        if let existingWindow = NSApp.windows.first(where: { $0.title == "Preferences" }) {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let view = PreferencesView()
            .environmentObject(preferences)
            .environmentObject(calendarManager)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        
        // Hold a reference to the window
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        
        // Close window when preferences close
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: nil
        ) { [weak windowController] _ in
            // Release the window controller when window closes
            _ = windowController
        }
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
