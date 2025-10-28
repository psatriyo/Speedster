//
//  ContentView.swift
//  Speedster
//
//  Created by Prayudi Satriyo on 29/10/25.
//

import SwiftUI
import MapKit
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region: MKCoordinateRegion
    @Published var speed: CLLocationSpeed?

    private let locationManager: CLLocationManager

    override init() {
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.00902)
        region = MKCoordinateRegion(
            center: defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        speed = nil
        locationManager = CLLocationManager()

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestWhenInUseAuthorization()
        handleAuthorizationStatus(locationManager.authorizationStatus)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationStatus(status)
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if CLLocationManager.locationServicesEnabled() {
                locationManager.startUpdatingLocation()
            }
        case .denied, .restricted:
            locationManager.stopUpdatingLocation()
            DispatchQueue.main.async {
                self.speed = nil
            }
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let coordinate = location.coordinate
        let updatedRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.region = updatedRegion
            }

            if location.speed >= 0 {
                self.speed = location.speed
            } else {
                self.speed = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.speed = nil
        }

        speed = location.speed >= 0 ? location.speed : nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        speed = nil
    }

    var speedInKilometersPerHour: Double? {
        guard let currentSpeed = speed, currentSpeed >= 0 else { return nil }
        return currentSpeed * 3.6
    }

    var speedInKilometersPerHour: Double? {
        guard let currentSpeed = speed, currentSpeed >= 0 else { return nil }
        return currentSpeed * 3.6
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var userTrackingMode: MapUserTrackingMode = .follow

    private static let speedFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumFractionDigits = 0
        formatter.numberFormatter = numberFormatter
        return formatter
    }()

    private var speedText: String {
        if let speed = locationManager.speedInKilometersPerHour {
            let measurement = Measurement(value: speed, unit: UnitSpeed.kilometersPerHour)
            return Self.speedFormatter.string(from: measurement)
        } else {
            return "– km/h"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Map(
                coordinateRegion: $locationManager.region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode
            )

            Text(speedText)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .monospacedDigit()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(radius: 4, x: 0, y: 2)
                .padding(.leading, 20)
                .padding(.bottom, 32)
                .animation(.easeInOut(duration: 0.25), value: speedText)
        }
        .onAppear {
            userTrackingMode = .follow
        }
    }
}

#Preview {
    ContentView()
}
