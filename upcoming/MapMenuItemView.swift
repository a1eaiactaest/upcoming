//
//  MapMenuItemView.swift
//  upcoming
//
//  Created by Piotrek Rybiec on 03/04/2025.
//

import MapKit

class MapMenuItemView: NSView {
    private let mapView = MKMapView()
    private let location: String
    private var coordinate: CLLocationCoordinate2D?

    init(location: String, frame: NSRect) {
        self.location = location
        super.init(frame: frame)
        setupMapView()
        geocodeLocation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMapView() {
        mapView.frame = bounds
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.showsZoomControls = false
        mapView.showsCompass = false
        addSubview(mapView)
    }

    private func geocodeLocation() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first, let location = placemark.location else { return }

            self.coordinate = location.coordinate
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = self.location
            self.mapView.addAnnotation(annotation)

            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.01,
                    longitudeDelta: 0.01
                )
            )
            self.mapView.setRegion(region, animated: false)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
    }
}
