//
//  CalendarManager.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 29/03/2025.
//

import Foundation
import Dispatch
import EventKit

class CalendarManager: ObservableObject {
    @Published var calendars: [EKCalendar] = []
    private let eventStore = EKEventStore()
    
    func loadCalendars() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        if granted {
            let calendars = eventStore.calendars(for: .event)
                .sorted { $0.title < $1.title }
            DispatchQueue.main.async {
                self.calendars = calendars
            }
        }
    }
}

