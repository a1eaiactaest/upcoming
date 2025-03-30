//
//  CalendarManager.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 30/03/2025.
//


import Foundation

extension CalendarManager {
    enum CalendarError: LocalizedError {
        case accessDenied
        case syncFailed(underlyingError: Error)
        
        var errorDescription: String? {
            switch self {
            case.accessDenied:
                return "calendar access was denied"
            case .syncFailed(let error):
                return "Sync failed: \(error.localizedDescription)"
            }
        }
    }
}
