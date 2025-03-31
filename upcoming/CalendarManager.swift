//
//  CalendarManager.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 29/03/2025.
//

import Foundation
import Dispatch
import EventKit
import Combine

class CalendarManager: NSObject, ObservableObject {
    @Published var calendars: [EKCalendar] = []
    let eventStore = EKEventStore()
    
    private var observer: Any?
    
    override init() {
        super.init()
        startObserving()
    }
    
    deinit {
        stopObserving()
    }
    
    func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            self?.handleCalendarChanges()
        }
    }
    
    func stopObserving() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc private func handleCalendarChanges() {
        /*
        Task {
            try await self.loadCalendars()
            //NotificationCenter.default.post(name: .calendarDataDidChange, object: nil)
        }
         */
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(performCalendarReload),
            object: nil
        )
        
        perform(
            #selector(performCalendarReload),
            with: nil,
            afterDelay: 0.5
        )
    }
    
    @objc private func performCalendarReload() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.loadCalendars()
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .calendarDataDidChange,
                        object: self.calendars
                    )
                }
            } catch {
                await MainActor.run {
                    NSLog("Calendar reload failed: \(error.localizedDescription)")
                    NotificationCenter.default.post(
                        name: .calendarSyncError,
                        object: error
                    )
                }
            }
        }
    }
    
    
    func loadCalendars() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        // Always request access if not fully authorized
        if status != .fullAccess {
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                throw CalendarError.accessDenied
            }
        }
        
        let calendars = eventStore.calendars(for: .event)
            .sorted { $0.title < $1.title }
        
        await MainActor.run {
            self.calendars = calendars
            NotificationCenter.default.post(
                name: .calendarDataDidChange,
                object: self.calendars
            )
        }
    }
    
    func filteredCalendars(selectedIDs: [String]) -> [EKCalendar] {
        selectedIDs.isEmpty ? calendars : calendars.filter {
            selectedIDs.contains($0.calendarIdentifier)
        }
        
    }
}

