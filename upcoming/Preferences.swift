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
    @AppStorage("skipConfirmationDisabled") var skipConfirmationDisabled = false
    
}

extension Preferences {
    func reset() {
        timeFormat = .relative
        selectedCalendarIds = []
        showLocation = true
        refreshInterval = 1
        skipConfirmationDisabled = false
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
