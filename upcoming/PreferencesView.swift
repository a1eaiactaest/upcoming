//
//  PreferencesView.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 29/03/2025.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferences: Preferences
    
    
    var body: some View {
        Form {
            Toggle("Show event location", isOn: $preferences.showLocation)
            Stepper("Refresh interval (minutes): \(preferences.refreshInterval)", value: $preferences.refreshInterval, in: 1...60)
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
        .padding()
        .frame(width: 400, height: 200)
    }

}
