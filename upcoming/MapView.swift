//
//  MapView.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 03/04/2025.
//

import SwiftUI
import MapKit

struct MapView: View {
    var coordinate: CLLocationCoordinate2D
    @State private var cameraPosition: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            Marker("Event Location", coordinate: coordinate)
        }
        .frame(height: 150)
        .cornerRadius(10)
    }
}
