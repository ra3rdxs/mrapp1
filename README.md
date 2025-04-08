# Medicine Reminder App

A Flutter application for managing medication reminders with local notifications.

## Features

- Create and manage medicine reminders
- Receive notifications when it's time to take medication
- Store reminder data locally on the device
- Simple, intuitive user interface

## Getting Started with FVM (Flutter Version Manager)

This project uses FVM to ensure consistent Flutter SDK versions across development environments.

### Prerequisites

- [Git](https://git-scm.com/downloads)
- [Flutter](https://docs.flutter.dev/get-started/install) (base installation)
- [Android Studio](https://developer.android.com/studio) with Android SDK
- [VS Code](https://code.visualstudio.com/download) (recommended)

### Installing FVM

#### Windows

**Using Chocolatey (Recommended)**

```
choco install fvm
```

#### macOS

**Option 1: Using Install Script**

```
curl -fsSL https://fvm.app/install.sh | bash
```

**Option 2: Using Homebrew**

```
brew tap leoafarias/fvm
brew install fvm
```

#### Linux

**Using Install Script**

```
curl -fsSL https://fvm.app/install.sh | bash
```

### Project Setup

1. **Clone the repository**:

   ```
   git clone https://github.com/ra3rdxs/mrapp1.git
   cd mrapp1
   ```

2. **Set up the project with FVM**:

   ```
   fvm install 3.24.0
   fvm use 3.24.0
   fvm flutter pub get
   ```

3. **Configure VS Code** (create `.vscode/settings.json`):

   ```json
   {
     "dart.flutterSdkPath": ".fvm/versions/3.24.0"
   }
   ```

4. **Run the app**:
   ```
   fvm flutter run
   ```

## Project Structure

```
lib/
├── features/
│   ├── auth/ - Authentication feature
│   │   ├── models/
│   │   ├── screens/
│   │   └── services/
│   └── medicine_reminders/ - Medicine reminder feature
│       ├── models/ - Data models
│       ├── screens/ - UI screens
│       ├── services/ - Backend services
│       └── widgets/ - Reusable UI components
├── shared/ - Shared utilities and components
└── main.dart - Entry point
```

## Notifications

The app uses the Flutter Local Notifications plugin to schedule medicine reminders. The notification service handles:

- Permission requests for notifications
- Scheduling notifications based on reminder times
- Canceling notifications when reminders are deleted or updated

## Troubleshooting

### FVM Issues

- **FVM not found**: Ensure it's added to your PATH
- **Version conflicts**: Run `fvm flutter doctor` to check your setup

### Dependency Issues

```
fvm flutter clean
fvm flutter pub get
```

### Android Emulator Issues

- Create a new AVD in Android Studio
- Ensure Intel HAXM is installed for hardware acceleration

## Development Commands

- **Run the app**: `fvm flutter run`
- **Build APK**: `fvm flutter build apk`
- **Check dependencies**: `fvm flutter pub outdated`
- **Run tests**: `fvm flutter test`
