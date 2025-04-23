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
        self.autoresizingMask = [.width]
        setupMapView()
        fetchCoordinates()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMapView() {
        mapView.wantsLayer = true
        mapView.layer?.cornerRadius = 10
        mapView.layer?.masksToBounds = true
        //mapView.layer?.borderWidth = 1
        //mapView.layer?.borderColor = NSColor.systemBlue.cgColor

        mapView.frame = bounds
        mapView.autoresizingMask = [.width, .height]

        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.showsZoomControls = false
        mapView.showsCompass = true

        addSubview(mapView)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        mapView.frame = bounds
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let superview = superview {
            frame.size.width = superview.frame.size.width
        }
    }

    private func fetchCoordinates() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    self.showErrorView()
                    return
                }

                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    self.showErrorView()
                    return
                }

                self.updateMap(with: location.coordinate)
            }
        }
    }

    private func updateMap(with coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = location
        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        )
        mapView.setRegion(region, animated: false)
    }

    private func showErrorView() {
        let errorLabel = NSTextField(labelWithString: "Map unavailable")
        errorLabel.frame = bounds
        errorLabel.alignment = .center
        addSubview(errorLabel)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
    }
}
