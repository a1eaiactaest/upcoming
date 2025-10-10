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
    private let padding: CGFloat = 8

    init(location: String, frame: NSRect) {
        self.location = location
        super.init(frame: frame)
        self.autoresizingMask = [.width]
        self.wantsLayer = true
        self.layer?.backgroundColor = .clear
        // Do not add the mapView yet; wait until geocoding succeeds
        configureMapViewAppearance()
        fetchCoordinates()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureMapViewAppearance() {
        mapView.wantsLayer = true
        mapView.layer?.cornerRadius = 10
        mapView.layer?.masksToBounds = true

        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.showsZoomControls = false
        mapView.showsCompass = true
    }

    private func layoutMapViewToPaddedBounds() {
        let paddedBounds = NSRect(
            x: bounds.origin.x + padding,
            y: bounds.origin.y + padding,
            width: bounds.width - (padding * 2),
            height: bounds.height - (padding * 2)
        )
        mapView.frame = paddedBounds
        mapView.autoresizingMask = [.width, .height]
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if mapView.superview === self {
            layoutMapViewToPaddedBounds()
        }
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
                    self.removeHostingMenuItem()
                    return
                }

                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    self.removeHostingMenuItem()
                    return
                }

                self.updateMap(with: location.coordinate)
            }
        }
    }

    private func updateMap(with coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate

        // Only now add the map view
        if mapView.superview == nil {
            addSubview(mapView)
            layoutMapViewToPaddedBounds()
        }

        mapView.removeAnnotations(mapView.annotations)
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

    private func removeHostingMenuItem() {
        // Find the NSMenuItem that hosts this view and remove it from the menu
        var responder: NSResponder? = self
        while let r = responder {
            if let menuItem = r as? NSMenuItem, let menu = menuItem.menu {
                // Remove the item; this hides the box entirely
                menu.removeItem(menuItem)
                return
            }
            responder = r.nextResponder
        }

        // Fallback: if we can’t find the menu item, just hide ourselves
        isHidden = true
        frame.size.height = 0
        needsLayout = true
    }
}
