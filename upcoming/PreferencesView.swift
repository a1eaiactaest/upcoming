//
//  PreferencesView.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 29/03/2025.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage("showLocation") var showLocation = true
    @AppStorage("refreshInterval") var refreshInterval = 5
    
    var body: some View {
        Form {
            Toggle("Show event location", isOn: $showLocation)
            Stepper("Refresh interval (minutes): \(refreshInterval)", value: $refreshInterval, in: 1...60)
        }
        .padding()
        .frame(width: 400, height: 200)
    }

}
