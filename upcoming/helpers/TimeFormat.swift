//
//  Preferences.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 29/03/2025.
//
import Foundation

enum TimeFormat: String, CaseIterable, Identifiable {
    case relative = "Relative (e.g., 'in 15 min')"
    case clock = "Clock time (e.g., 'at 2:30PM')"
    case hybrid = "Relative and clock time (e.g., 'in 15 min (2:30PM)')"
    case hybridReverse = "Clock time and relative (e.g., 'at 2:30PM (in 15 min)')"
    
    var id: String { self.rawValue }
}
