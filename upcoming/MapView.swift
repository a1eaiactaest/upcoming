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
    var location: String

    @State private var cameraPosition: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D, location: String) {
        self.coordinate = coordinate
        self.location = location
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                Map(position: $cameraPosition) {
                    Marker(location, coordinate: coordinate)
                }
                .cornerRadius(10)
            }
            .frame(height: 150)
            .border(Color.blue)
        }
        .border(Color.green)
        .fixedSize(horizontal: false, vertical: true)
    }
}
