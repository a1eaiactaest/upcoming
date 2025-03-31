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
import ObjectiveC

extension NSStatusItem {
    private static var mainMenuKey = "mainMenuKey"
    private static var settingsMenuKey = "settingsMenuKey"
    
    var mainMenu: NSMenu? {
        get { objc_getAssociatedObject(self, &NSStatusItem.mainMenuKey) as? NSMenu }
        set { objc_setAssociatedObject(self, &NSStatusItem.mainMenuKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var settingsMenu: NSMenu? {
        get { objc_getAssociatedObject(self, &NSStatusItem.settingsMenuKey) as? NSMenu }
        set { objc_setAssociatedObject(self, &NSStatusItem.settingsMenuKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var calendarManager = CalendarManager()
    private var cancellables = Set<AnyCancellable>()
    
    var statusBarItem: NSStatusItem!
    var eventStore = EKEventStore()
    var timer: Timer?
    var preferences = Preferences()
    
    // Add these properties
    private var mainPopover: NSPopover?
    private var settingsPopover: NSPopover?
    
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
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup popovers
        mainPopover = NSPopover()
        mainPopover?.behavior = .transient
        mainPopover?.contentSize = NSSize(width: 300, height: 400)
        mainPopover?.contentViewController = NSHostingController(
            rootView: EventMenuView()
                .environmentObject(preferences)
                .environmentObject(calendarManager)
        )
        
        settingsPopover = NSPopover()
        settingsPopover?.behavior = .transient
        settingsPopover?.contentSize = NSSize(width: 200, height: 100)
        settingsPopover?.contentViewController = NSHostingController(
            rootView: SettingsMenuView()
                .environmentObject(preferences)
        )
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
            updateEventMenu() // Update menu to show "No upcoming events"
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
        
        updateEventMenu()
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
            return ((formatter.string(from: now, to: event.endDate) ?? "") + " left")
        }
        
        // Otherwise show time until event starts
        return "in " + (formatter.string(from: now, to: event.startDate) ?? "")
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
    
    func performEventDeletion(_ event: EKEvent) {
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

    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        let isRightClick = event.type == .rightMouseUp || 
                          (event.type == .leftMouseUp && event.modifierFlags.contains(.control))
        
        if isRightClick {
            if settingsPopover?.isShown == true {
                settingsPopover?.close()
            } else {
                mainPopover?.close()
                settingsPopover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            }
        } else {
            if mainPopover?.isShown == true {
                mainPopover?.close()
            } else {
                settingsPopover?.close()
                updateEventMenu()
                mainPopover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            }
        }
    }

    private func updateEventMenu() {
        guard let menu = statusBarItem.mainMenu else { return }
        menu.removeAllItems()
        
        if let event = fetchNextEvent() {
            // Add event title
            menu.addItem(NSMenuItem(
                title: event.title ?? "Untitled Event",
                action: nil,
                keyEquivalent: ""
            ))
            
            // Add time
            menu.addItem(NSMenuItem(
                title: "\(event.startDate.formatted()) - \(event.endDate.formatted())",
                action: nil,
                keyEquivalent: ""
            ))
            
            // Add location if available
            if let location = event.location, !location.isEmpty {
                menu.addItem(NSMenuItem(
                    title: location,
                    action: nil,
                    keyEquivalent: ""
                ))
            }
            
            // Add skip option
            menu.addItem(NSMenuItem.separator())
            let skipItem = NSMenuItem(
                title: "Skip >>",
                action: #selector(skipEvent),
                keyEquivalent: ""
            )
            skipItem.representedObject = event
            menu.addItem(skipItem)
        } else {
            menu.addItem(NSMenuItem(
                title: "No upcoming events",
                action: nil,
                keyEquivalent: ""
            ))
        }
    }

    private func setupMyApp() {
        // TODO: Add any intialization steps here.
        print("Application started up!")
    }
}

// Create new SwiftUI views for the popovers
struct EventMenuView: View {
    @EnvironmentObject var preferences: Preferences
    @EnvironmentObject var calendarManager: CalendarManager
    
    var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let event = appDelegate?.fetchNextEvent() {
                Text(event.title ?? "Untitled Event")
                    .font(.headline)
                Text("\(event.startDate.formatted()) - \(event.endDate.formatted())")
                    .font(.subheadline)
                if let location = event.location {
                    Text(location)
                        .font(.subheadline)
                }
                Divider()
                Button("Skip >>") {
                    if let delegate = appDelegate {
                        //delegate.skipEvent(NSMenuItem(representedObject: event))
                        delegate.performEventDeletion(event)
                    }
                }
            } else {
                Text("No upcoming events")
                    .font(.headline)
            }
        }
        .padding()
    }
}

struct SettingsMenuView: View {
    @EnvironmentObject var preferences: Preferences
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack(spacing: 12) {
            Button("Preferences...") {
                NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }
}
