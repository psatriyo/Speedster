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
    @Published var useMetric: Bool = true // true for km/h, false for mph
    @Published var useDrivingView: Bool = false // true for driving perspective, false for standard above view
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var userHeading: CLLocationDirection = 0

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
        
        // Enable heading updates for driving view
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 5 // Update when heading changes by 5 degrees
        }
        
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
                if CLLocationManager.headingAvailable() {
                    locationManager.startUpdatingHeading()
                }
            }
        case .denied, .restricted:
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
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
        
        // Calculate heading from movement if we have a previous location
        if let lastLoc = lastLocation {
            let distance = lastLoc.distance(from: location)
            
            // Only add to total distance if the movement is significant and reasonable (not GPS jitter)
            if distance > 5 && distance < 100 {
                DispatchQueue.main.async {
                    self.totalDistance += distance
                }
            }
            
            // Calculate course/heading from movement if traveling fast enough
            if distance > 10 { // Only calculate course if moved at least 10 meters
                let course = lastLoc.bearing(to: location)
                DispatchQueue.main.async {
                    // Use course from movement if compass heading is not reliable
                    if self.userHeading == 0 || abs(course - self.userHeading) > 45 {
                        self.userHeading = course
                    }
                }
            }
        }
        
        lastLocation = location
        
        DispatchQueue.main.async {
            self.userLocation = coordinate
            
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Only update heading if it's accurate enough
        if newHeading.headingAccuracy >= 0 {
            DispatchQueue.main.async {
                // Use true heading if available, otherwise magnetic heading
                let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
                self.userHeading = heading
            }
        }
    }

    var speedInKilometersPerHour: Double {
        return speed >= 0 ? speed * 3.6 : 0
    }
    
    var speedInMilesPerHour: Double {
        return speed >= 0 ? speed * 2.237 : 0
    }
    
    var currentSpeed: Double {
        return useMetric ? speedInKilometersPerHour : speedInMilesPerHour
    }
    
    var speedUnit: String {
        return useMetric ? "km/h" : "mph"
    }
    
    var distanceInKilometers: Double {
        return totalDistance / 1000.0
    }
    
    var distanceInMiles: Double {
        return totalDistance / 1609.34
    }
    
    var currentDistance: Double {
        return useMetric ? distanceInKilometers : distanceInMiles
    }
    
    var distanceUnit: String {
        return useMetric ? "km" : "mi"
    }
    
    func resetDistance() {
        totalDistance = 0
    }
    
    func toggleSpeedUnit() {
        useMetric.toggle()
    }
}

// Extension to calculate bearing between two locations
extension CLLocation {
    func bearing(to destination: CLLocation) -> CLLocationDirection {
        let lat1 = coordinate.latitude.degreesToRadians
        let lon1 = coordinate.longitude.degreesToRadians
        let lat2 = destination.coordinate.latitude.degreesToRadians
        let lon2 = destination.coordinate.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let radiansBearing = atan2(y, x)
        let degreesBearing = radiansBearing.radiansToDegrees
        
        return (degreesBearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
}

// Custom MapView for 3D driving perspective
struct CustomMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        
        // Set initial region
        mapView.setRegion(locationManager.region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update the camera based on driving view setting
        if locationManager.useDrivingView, let userLocation = locationManager.userLocation {
            // Set up 3D driving perspective camera
            let camera = MKMapCamera()
            camera.centerCoordinate = userLocation
            camera.altitude = 800 // Height above ground in meters
            camera.pitch = 60 // Angle from straight down (0) to horizontal (90)
            
            // Use user heading directly - MapKit will position camera correctly
            camera.heading = locationManager.userHeading
            
            uiView.setCamera(camera, animated: true)
        } else {
            // Standard top-down view - just set the region
            if !locationManager.useDrivingView {
                uiView.setRegion(locationManager.region, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Update the location manager's region when user pans/zooms in standard view
            if !parent.locationManager.useDrivingView {
                DispatchQueue.main.async {
                    self.parent.locationManager.region = mapView.region
                }
            }
        }
    }
}

struct MainView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var userTrackingMode: MapUserTrackingMode = .none

    private var speedText: String {
        let speed = locationManager.currentSpeed
        if speed > 0 {
            return String(format: "%.1f %@", speed, locationManager.speedUnit)
        } else {
            return "– \(locationManager.speedUnit)"
        }
    }
    
    private var distanceText: String {
        let distance = locationManager.currentDistance
        return String(format: "%.2f %@", distance, locationManager.distanceUnit)
    }

    var body: some View {
        ZStack {
            // Use SwiftUI Map for reliability, with custom map for driving mode
            if locationManager.useDrivingView {
                CustomMapView(locationManager: locationManager)
                    .ignoresSafeArea()
            } else {
                Map(
                    coordinateRegion: $locationManager.region,
                    interactionModes: [.pan, .zoom],
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode
                )
                .ignoresSafeArea()
            }
            
            // Location button in top-left corner
            VStack {
                HStack {
                    Button(action: {
                        if locationManager.useDrivingView {
                            // Reset to user location in 3D view
                            if let userLocation = locationManager.userLocation {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    locationManager.region = MKCoordinateRegion(
                                        center: userLocation,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                }
                            }
                        } else {
                            // Standard 2D map tracking
                            withAnimation(.easeInOut(duration: 0.5)) {
                                userTrackingMode = .follow
                            }
                        }
                    }) {
                        Image(systemName: "location")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .shadow(radius: 4, x: 0, y: 2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    Spacer()
                }
                Spacer()
            }

            // Speedometer at bottom, above tab bar
            VStack {
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
                .padding(.vertical, 20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 6, x: 0, y: 3)
                .padding(.horizontal, 20)
                .padding(.bottom, 20) // Space above tab bar
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
                Section(header: Text("Map View")) {
                    // Map View Style Toggle
                    HStack {
                        Text("Map Perspective")
                        Spacer()
                        Picker("Map View", selection: $locationManager.useDrivingView) {
                            Text("Above").tag(false)
                            Text("Driving").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 140)
                    }
                    
                    Text(locationManager.useDrivingView ? 
                         "Shows the map rotated to match your heading direction, like a GPS navigation system. Map will rotate when you start moving." :
                         "Shows the map from directly above with a fixed north-up orientation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Speed & Distance")) {
                    // Speed Unit Toggle
                    HStack {
                        Text("Speed Unit")
                        Spacer()
                        Picker("Speed Unit", selection: $locationManager.useMetric) {
                            Text("km/h").tag(true)
                            Text("mph").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Total Distance")
                        Spacer()
                        Text(String(format: "%.2f %@", locationManager.currentDistance, locationManager.distanceUnit))
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
