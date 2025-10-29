# Speedster 🏎️

A modern, feature-rich speedometer and distance tracking app for iOS built with SwiftUI and MapKit. Track your speed in real-time with support for both metric and imperial units, distance tracking, and an immersive 3D driving perspective view.

## Features ✨

### 🚗 Dual Map Views
- **Above View**: Traditional top-down map perspective with fixed north-up orientation
- **Driving View**: Immersive 3D perspective that follows from behind your location with realistic camera angles

### 📊 Speed Tracking
- Real-time speed display with large, easy-to-read speedometer
- Support for both **km/h** and **mph** units
- Smooth animations and transitions
- Monospaced digits for consistent display

### 📏 Distance Tracking
- Cumulative distance counter since last reset
- Intelligent GPS filtering to avoid measurement errors
- Tracks only significant movements (>5m, <100m) to prevent GPS jitter
- Supports both kilometers and miles

### ⚙️ Comprehensive Settings
- Toggle between metric (km/h, km) and imperial (mph, mi) units
- Switch between "Above" and "Driving" map perspectives
- Reset distance counter with confirmation dialog
- Clean, native iOS settings interface

### 🎯 Smart Location Management
- Automatic location permission handling
- Efficient GPS updates with 10-meter distance filtering
- Hybrid heading detection using both compass and movement-based calculations
- Optimized battery usage with smart update intervals

## Screenshots 📸

### Main Interface
- Large speedometer display centered at bottom of screen
- Real-time speed updates with smooth animations
- Total distance display below speedometer
- Clean, modern UI with ultra-thin material backgrounds

### Driving View
- 3D angled perspective (60° pitch, 800m altitude)
- Camera positioned behind user location
- Map rotates to match heading direction
- Immersive navigation-style experience

### Settings Panel
- Map perspective toggle (Above/Driving)
- Speed unit selection (km/h/mph)
- Distance counter with reset functionality
- Version information

## Technical Details 🔧

### Architecture
- **SwiftUI** for modern, declarative UI
- **MapKit** for mapping and location services
- **Core Location** for GPS and heading data
- **UIViewRepresentable** for custom 3D map implementation

### Key Components
- `LocationManager`: Core location and GPS management
- `CustomMapView`: 3D driving perspective implementation
- `MainView`: Primary speedometer interface
- `SettingsView`: Configuration and preferences

### Location Services
- **GPS Accuracy**: `kCLLocationAccuracyBest` for precise tracking
- **Distance Filter**: 10 meters to balance accuracy and battery life
- **Heading Updates**: 5-degree filter for smooth rotation
- **Activity Type**: Configured for fitness/automotive use

### Camera System (3D Mode)
- **Altitude**: 800 meters for optimal perspective
- **Pitch**: 60 degrees for driving-style view
- **Heading**: Dynamic rotation based on user movement
- **Smooth Transitions**: Animated camera movements

## Requirements 📋

- **iOS 14.0+**
- **Xcode 12.0+**
- **Swift 5.3+**
- **Location Services** enabled
- **Device with GPS** capability

## Installation 🛠️

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/speedster.git
   ```

2. Open `Speedster.xcodeproj` in Xcode

3. Build and run on your iOS device (location services require physical device)

## Usage 🚀

### First Launch
1. Grant location permissions when prompted
2. App will automatically center on your current location
3. Start moving to see speed and distance tracking

### Switching Map Views
1. Go to **Settings** tab
2. Toggle **Map Perspective** between "Above" and "Driving"
3. "Driving" mode activates 3D perspective when moving

### Changing Units
1. Navigate to **Settings**
2. Switch **Speed Unit** between km/h and mph
3. All displays update automatically

### Resetting Distance
1. In **Settings**, tap **Reset Distance Counter**
2. Confirm the action in the alert dialog
3. Distance counter returns to zero

## Code Structure 📁

```
Speedster/
├── SpeedsterApp.swift          # Main app entry point
├── ContentView.swift           # Core UI components and logic
├── Persistence.swift           # Core Data setup (unused)
└── README.md                  # This file
```

### Key Classes

#### `LocationManager`
- Manages GPS location and heading updates
- Handles distance calculations and filtering
- Provides speed data in multiple units
- Manages location permissions

#### `CustomMapView`
- UIViewRepresentable wrapper for MKMapView
- Implements 3D camera controls
- Handles driving perspective calculations
- Manages map interactions and delegates

#### `MainView`
- Primary speedometer interface
- Speed and distance display
- Map view container
- Location centering controls

#### `SettingsView`
- Unit preferences (metric/imperial)
- Map view mode selection
- Distance reset functionality
- App information display

## Privacy 🔒

This app requires location services to function properly. Location data is:
- ✅ Used only for speed and distance calculations
- ✅ Never transmitted or stored remotely
- ✅ Processed entirely on-device
- ✅ Not shared with third parties

## Known Issues 🐛

- 3D driving view requires device movement to calculate accurate heading
- Compass accuracy may vary in areas with magnetic interference
- GPS accuracy depends on environmental conditions

## Future Enhancements 🚧

- [ ] Speed limit warnings and notifications
- [ ] Trip history and statistics
- [ ] Export trip data functionality
- [ ] Apple Watch companion app
- [ ] Dark mode optimization
- [ ] Landscape orientation support
- [ ] Custom speedometer themes

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 👏

- Built with SwiftUI and MapKit frameworks
- Uses Core Location for precise GPS tracking
- Inspired by modern navigation apps
- Thanks to the iOS development community

## Author ✍️

**Prayudi Satriyo**
- Created: October 29, 2025
- Platform: iOS (SwiftUI)

---

**Speedster** - Track your speed with style! 🏁