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
    
    func loadCalendars() {
        eventStore.requestFullAccessToEvents { granted, error in
            if granted {
                DispatchQueue.main.async {
                    self.calendars = self.eventStore.calendars(for: .event)
                        .sorted { $0.title < $1.title }
                }
            }
        }
    }
}

