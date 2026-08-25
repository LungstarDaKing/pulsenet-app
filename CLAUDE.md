# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the PulseNet Flutter application.

## Project Overview

PulseNet is a Flutter-based emergency health and safety application featuring:
- Emergency SOS functionality with countdown
- Vitals monitoring (Bluetooth heart rate monitor + camera-based pulse estimation)
- First aid information
- Emergency contacts
- User profile management
- App locking for security
- Onboarding flow

## Project Structure

```
lib/
├── main.dart                 # App entry point and initialization
├── theme.dart                # Theme configuration (light/dark modes)
├── data/                     # Static data assets
│   ├── distress_phrases/     # Distress phrase data for SOS feature
│   └── first_aid/            # First aid information
├── screens/                  # UI screens
│   ├── dashboard_screen.dart # Main dashboard with feature tiles
│   ├── vitals_screen.dart    # Heart rate monitoring interface
│   ├── first_aid_screen.dart # First aid information display
│   ├── contacts_screen.dart  # Emergency contacts management
│   ├── profile_screen.dart   # User profile and settings
│   ├── onboarding_screen.dart# Initial app walkthrough
│   ├── app_lock_screen.dart  # Security lock screen
│   └── sos_confirmation_screen.dart # SOS confirmation after countdown
├── services/                 # Service layer
│   ├── storage_service.dart  # Local data persistence (SharedPreferences)
│   ├── bluetooth_heart_rate_service.dart # Bluetooth LE heart rate monitoring
│   ├── distress_listener_service.dart    # Emergency SOS triggering
│   └── sos_service.dart      # App data (SharedPreferences)
├── widgets/                  # Reusable UI components
│   └── sos_button.dart       # Custom SOS button with countdown
└── assets/                   # Static assets
    ├── images/               # App images and logos
    └── data/                 # JSON data files for distress phrases and first aid

test/
└── widget_test.dart          # Basic widget test example

android/                      # Android-specific code
ios/                          # iOS-specific code
web/                          # Web implementation
windows/                      # Windows desktop implementation
linux/                        # Linux desktop implementation
macos/                        # macOS desktop implementation
```

## Development Commands

### Setup
```bash
# Get dependencies
flutter pub get

# Run the app on a connected device or emulator
flutter run

# For web
flutter run -d chrome

# For desktop (Windows/macOS/Linux)
flutter run -d windows    # or macos, linux
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Build Commands
```bash
# Build APK (Android)
flutter build apk --release

# Build iOS
flutter build ios --release

# Build web
flutter build web

# Build desktop (Windows example)
flutter build windows
```

### Code Analysis
```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Check for outdated dependencies
flutter pub outdated
```

## Architecture Overview

### State Management
PulseNet uses the Provider package for state management:
- `StorageService` is provided at the root level for accessing persisted data
- Services like `DistressListenerService` are instantiated in the main app
- UI components consume services through `Provider.of<T>(context)` or `context.read<T>()`

### Key Components

1. **App Initialization** (`main.dart`):
   - Sets up Providers for `StorageService`
   - Initializes `DistressListenerService`
   - Handles onboarding flow and app lock state

2. **Navigation**:
   - Uses named routes implicitly through Navigator.push
   - Dashboard screen serves as home with grid navigation to features
   - SOS button uses direct navigation to confirmation screen

3. **Services**:
   - `StorageService`: Handles SharedPreferences for user settings
   - `BluetoothHeartRateService`: Manages Bluetooth LE heart rate monitoring
   - `DistressListenerService`: Monitors for distress triggers (placeholder)
   - `SosService`: Handles SOS triggering logic

4. **UI Patterns**:
   - Consistent theming using `ThemeData` with custom colors
   - Reusable widgets like `SosButton`
   - Card-based dashboard layout
   - Responsive grid layouts

### Key Features Implementation

1. **SOS Functionality**:
   - Implemented via `SosButton` widget with countdown
   - Navigates to `SosConfirmationScreen` after countdown
   - Actual SOS triggering would be in `SosService` (placeholder)

2. **Vitals Monitoring**:
   - Bluetooth heart rate monitoring via `flutter_blue_plus`
   - Camera-based pulse estimation via `camera` package
   - Toggle between connection methods in VitalsScreen

3. **Data Persistence**:
   - Uses `shared_preferences` for simple key-value storage
   - Stores onboarding completion, app lock settings, etc.

## Common Development Tasks

### Adding a New Screen
1. Create a new file in `lib/screens/` (e.g., `new_feature_screen.dart`)
2. Implement a StatelessWidget or StatefulWidget
3. Add navigation from DashboardScreen or appropriate location
4. Consider if it needs access to services (provide via Provider if needed)

### Adding a Service
1. Create a new file in `lib/services/`
2. Implement the service logic (e.g., API calls, device communication)
3. Provide it via Provider if it needs to be accessed throughout the app
4. Initialize it in `main.dart` if it needs lifecycle management

### Working with Platform-Specific Code
- Platform-specific implementations go in the respective folders (`android/`, `ios/`, etc.)
- Use platform channels or plugins like `flutter_blue_plus` for cross-platform functionality
- For simple platform checks, use `Platform.isIOS`, `Platform.isAndroid`, etc.

### Asset Management
- Add images to `assets/images/` and declare in `pubspec.yaml`
- Add JSON/data files to `assets/data/` and declare in `pubspec.yaml`
- Use `rootBundle.loadString()` or `rootBundle.load()` to access assets

## Code Style
- Follows Flutter/Dart conventions
- Uses Provider for state management
- Widgets are kept small and focused
- Services handle business logic and side effects
- Constants and styling centralized in `theme.dart`

## Assets and Resources
- Logo and images stored in `assets/images/`
- Distress phrases and first aid data stored as JSON in `assets/data/`
- Custom icons/fonts would go in appropriate asset folders and be declared in pubspec.yaml