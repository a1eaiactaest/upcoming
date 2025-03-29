//
//  Preferences.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 29/03/2025.
//

import SwiftUI

class Preferences: ObservableObject {
    @AppStorage("timeFromat") var timeFormat: TimeFormat = .relative
    
    @AppStorage("selectedCalendars", store: UserDefaults.standard)
    private var selectedCalendarsStorage = StringArrayStorage(wrappedValue: [])
    var selectedCalendarIds: [String] {
        get { selectedCalendarsStorage.wrappedValue }
        set { selectedCalendarsStorage.wrappedValue = newValue }
    }
    
    @AppStorage("showLocation") var showLocation = true
    @AppStorage("refreshInterval") var refreshInterval = 1 // in minutes
    
    enum TimeFormat: String, CaseIterable, Identifiable {
        case relative = "Relative (e.g., 'in 15 min')"
        case clock = "Clock time (e.g., 'at 2:30PM')"
        case hybrid = "Relative and clock time (e.g., 'in 15 min (2:30PM)')"
        case hybridReverse = "Clock time and relative (e.g., 'at 2:30PM (in 15 min)')"
        
        var id: String { self.rawValue }
    }
}

@propertyWrapper
struct StringArrayStorage: RawRepresentable {
    var rawValue: String
    var wrappedValue: [String] {
        get { rawValue.components(separatedBy: "|") }
        set { rawValue = newValue.joined(separator: "|") }
    }
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    init(wrappedValue: [String]) {
        self.rawValue = wrappedValue.joined(separator: "|")
    }
}

extension StringArrayStorage: Codable {}
