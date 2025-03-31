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
    @EnvironmentObject var calendarManager: CalendarManager
    
    @State private var refreshFlag = false;
    
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
        .onReceive(
            NotificationCenter.default.publisher(for: .calendarDataDidChange)) {
                _ in refreshFlag.toggle()
            }
            .id(refreshFlag)
    }
    
    private func calendarBinding(for calendar: EKCalendar) -> Binding<Bool> {
        Binding(
            get: {
                preferences.selectedCalendarIds.contains(calendar.calendarIdentifier) ||
                preferences.selectedCalendarIds.isEmpty
            },
            set: { isSelected in
                var newSelection = preferences.selectedCalendarIds
                if isSelected {
                    if !newSelection.isEmpty && !newSelection.contains(calendar.calendarIdentifier) {
                        newSelection.append(calendar.calendarIdentifier)
                    }
                } else {
                    if newSelection.isEmpty {
                        newSelection = calendarManager.calendars
                            .map { $0.calendarIdentifier }
                            .filter { $0 != calendar.calendarIdentifier }
                    } else {
                        newSelection.removeAll { $0 == calendar.calendarIdentifier }
                    }
                }
                preferences.selectedCalendarIds = newSelection
            }
        )
    }

}
