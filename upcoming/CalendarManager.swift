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

class CalendarManager: ObservableObject {
    @Published var calendars: [EKCalendar] = []
    let eventStore = EKEventStore()
    
    private var observer: Any?
    
    init() {
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
    
    private func handleCalendarChanges() {
        Task {
            try await self.loadCalendars()
            //NotificationCenter.default.post(name: .calendarDataDidChange, object: nil)
        }
    }
    
    
    func loadCalendars() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        if granted {
            let calendars = eventStore.calendars(for: .event)
                .sorted { $0.title < $1.title }
            await MainActor.run {
                self.calendars = calendars
            }
        }
    }
    
    func filteredCalendars(selectedIDs: [String]) -> [EKCalendar] {
        selectedIDs.isEmpty ? calendars : calendars.filter {
            selectedIDs.contains($0.calendarIdentifier)
        }
        
    }
}

