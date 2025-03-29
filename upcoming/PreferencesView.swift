//
//  PreferencesView.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 29/03/2025.
//

import SwiftUI
import EventKit

struct PreferencesView: View {
    @EnvironmentObject var preferences: Preferences
    @StateObject private var calendarManager = CalendarManager();
    
    
    var body: some View {
        Form {
            Section(header: Text("Display")) {
                Toggle(
                    "Show event location",
                    isOn: $preferences.showLocation
                )
                Picker("Time display format:", selection: $preferences.timeFormat) {
                    ForEach(TimeFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                //.pickerStyle(.radioGroup)

            }
            Section(header: Text("Behavior")) {
                Stepper(
                    "Refresh interval: \(preferences.refreshInterval) min",
                    value: $preferences.refreshInterval,
                    in: 1...60,
                    step: 1
                )
                Toggle(
                    "Show confirmation before deleting events",
                    isOn: Binding(
                        get: {
                            !preferences.skipConfirmationDisabled
                        },
                        set: {
                            preferences.skipConfirmationDisabled = !$0
                        }
                    )
                )
            }
            Section(header: Text("Calendars")) {
                ForEach(calendarManager.calendars, id: \.calendarIdentifier) {
                    calendar in
                    Toggle(calendar.title, isOn: calendarBinding(for: calendar))
                }
            }
        }
        .padding(10)
        .frame(minWidth: 400, idealWidth: 450, maxWidth: 500)
    }
    
    private func calendarBinding(for calendar: EKCalendar) -> Binding<Bool> {
        Binding(
            get: {
                preferences.selectedCalendarIds.contains(calendar.calendarIdentifier) ||
                preferences.selectedCalendarIds.isEmpty
            },
            set: {
                isSelected in
                if isSelected {
                    if !preferences.selectedCalendarIds.isEmpty {
                        preferences.selectedCalendarIds.append(
                            calendar.calendarIdentifier
                        )
                    }
                } else {
                    if preferences.selectedCalendarIds.isEmpty {
                        preferences.selectedCalendarIds = calendarManager.calendars
                            .map { $0.calendarIdentifier }
                            .filter { $0 != calendar.calendarIdentifier }
                    } else {
                        preferences.selectedCalendarIds.removeAll { $0 == calendar.calendarIdentifier}
                    }
                }
            }
        )
    }

}
