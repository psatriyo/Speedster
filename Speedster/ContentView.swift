//
//  ContentView.swift
//  Speedster
//
//  Created by Prayudi Satriyo on 29/10/25.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region: MKCoordinateRegion
    @Published var speed: CLLocationSpeed = 0
    @Published var totalDistance: CLLocationDistance = 0

    private let locationManager: CLLocationManager
    private var isInitialLocationSet = false
    private var lastLocation: CLLocation?

    override init() {
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.00902)
        region = MKCoordinateRegion(
            center: defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        locationManager = CLLocationManager()

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Only update when moved 10 meters
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestWhenInUseAuthorization()
        handleAuthorizationStatus(locationManager.authorizationStatus)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
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
                self.speed = 0
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
        
        // Calculate distance from last location
        if let lastLoc = lastLocation {
            let distance = lastLoc.distance(from: location)
            // Only add to total distance if the movement is significant and reasonable (not GPS jitter)
            if distance > 5 && distance < 100 {
                DispatchQueue.main.async {
                    self.totalDistance += distance
                }
            }
        }
        
        lastLocation = location
        
        DispatchQueue.main.async {
            // Only update the region center on first location or if the user is tracking
            if !self.isInitialLocationSet {
                let initialRegion = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.region = initialRegion
                }
                self.isInitialLocationSet = true
            } else {
                // Only update the center, preserve the current zoom level (span)
                let updatedRegion = MKCoordinateRegion(
                    center: coordinate,
                    span: self.region.span
                )
                // Use a subtle animation for center updates
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.region = updatedRegion
                }
            }

            self.speed = location.speed >= 0 ? location.speed : 0
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.speed = 0
        }
    }

    var speedInKilometersPerHour: Double {
        return speed >= 0 ? speed * 3.6 : 0
    }
    
    var distanceInKilometers: Double {
        return totalDistance / 1000.0
    }
    
    func resetDistance() {
        totalDistance = 0
    }
}

struct MainView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var userTrackingMode: MapUserTrackingMode = .none

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
    
    private static let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0
        formatter.numberFormatter = numberFormatter
        return formatter
    }()

    private var speedText: String {
        let speed = locationManager.speedInKilometersPerHour
        if speed > 0 {
            let measurement = Measurement(value: speed, unit: UnitSpeed.kilometersPerHour)
            return Self.speedFormatter.string(from: measurement)
        } else {
            return "– km/h"
        }
    }
    
    private var distanceText: String {
        let distance = locationManager.distanceInKilometers
        let measurement = Measurement(value: distance, unit: UnitLength.kilometers)
        return Self.distanceFormatter.string(from: measurement)
    }

    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $locationManager.region,
                interactionModes: [.pan, .zoom],
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode
            )
            .ignoresSafeArea()

            // Centered speedometer
            VStack(spacing: 8) {
                Spacer()
                
                VStack(spacing: 12) {
                    // Large speedometer
                    Text(speedText)
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .animation(.easeInOut(duration: 0.25), value: speedText)
                    
                    // Distance information
                    Text("Total distance: \(distanceText)")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 8, x: 0, y: 4)
                
                Spacer()
            }
            
            // Location button in corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            userTrackingMode = .follow
                        }
                    }) {
                        Image(systemName: "location")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            userTrackingMode = .none
        }
    }
}

struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Distance Tracking")) {
                    HStack {
                        Text("Total Distance")
                        Spacer()
                        Text("\(String(format: "%.2f", locationManager.distanceInKilometers)) km")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Distance Counter")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Distance Counter", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    locationManager.resetDistance()
                }
            } message: {
                Text("This will reset your total distance counter to zero. This action cannot be undone.")
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(locationManager: locationManager)
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("Main")
                }
                .tag(0)
            
            SettingsView(locationManager: locationManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
