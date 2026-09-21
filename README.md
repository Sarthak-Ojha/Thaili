# Thaili

A personal finance management application built with Flutter, designed to help users track expenses, manage budgets, and achieve financial goals.

## Features

- **Expense Tracking**: Log and categorize daily expenses with ease
- **Budget Management**: Set and monitor monthly budgets for different categories
- **Financial Goals**: Create and track progress towards savings goals
- **Analytics**: Visualize spending patterns with comprehensive analytics
- **Offline-First**: All data stored locally with SQLite, no internet required
- **Secure**: Hardware-backed encryption for sensitive financial data
- **Recurring Transactions**: Track recurring expenses and income
- **Calendar View**: Visual calendar interface for money transactions
- **Data Export**: Export financial data for backup or analysis

## Tech Stack

- **Framework**: Flutter 3.47.1
- **Language**: Dart 3.13.1
- **Database**: SQLite with sqflite
- **Security**: flutter_secure_storage with Android Keystore
- **State Management**: Custom state management with persistence
- **Testing**: Comprehensive unit, widget, and integration tests

## Getting Started

### Prerequisites

- Flutter SDK 3.13.0 or higher
- Android Studio / Xcode (for mobile development)
- A code editor (VS Code, Android Studio, etc.)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd thaili
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Building for Production

### Windows Release Build (Current Focus)

**Important Security Note**: This is the current deployment target. Windows builds are distributed via direct download from personal website.

To build a Windows release executable:
```bash
flutter build windows --release
```

The build output will be in `build/windows/x64/runner/Release/thaili.exe`

**Requirements for Windows builds:**
- Visual Studio Community 2022 with "Desktop development with C++" workload
- Windows 10 or later development machine
- Flutter SDK with Windows desktop enabled

### Android Release Build (Future)

The app is configured with release signing using the production keystore for future Android deployment.

**Important Security Note**: The keystore file (`thaili-release.keystore`) and `key.properties` are excluded from version control. Keep these files secure and never commit them to public repositories.

To build a release APK:
```bash
flutter build apk --release
```

To build an App Bundle for Google Play Store:
```bash
flutter build appbundle --release
```

The build output will be in `build/app/outputs/flutter-apk/` (APK) or `build/app/outputs/bundle/release/` (App Bundle).

### iOS Release Build (Future)

To build for iOS:
```bash
flutter build ios --release
```

Note: iOS builds require:
- macOS development machine
- Xcode installed
- Apple Developer account for App Store distribution
- Proper code signing configuration in Xcode

## Package Information

- **Windows**: Direct distribution via sarthakojha.com.np
- **Android Package Name**: `com.sarthak.thaili` (configured for future)
- **iOS Bundle Identifier**: `com.sarthak.thaili` (configured for future)
- **Current Version**: 1.0.0 (Build 1)

## Development

### Running Tests

Run all tests:
```bash
flutter test
```

Run specific test suites:
```bash
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
```

### Code Quality

Run linter:
```bash
flutter analyze
```

Format code:
```bash
dart format .
```

## Deployment Checklist

### Windows Deployment (Current)
- [ ] Install Visual Studio with C++ workload
- [ ] Build Windows release executable
- [ ] Test executable on clean Windows machine
- [ ] Create download page on personal website
- [ ] Upload executable to website
- [ ] Test download process
- [ ] Create user support channels
- [ ] Prepare for user feedback

### Future Mobile Deployment
- [ ] Update version numbers in `pubspec.yaml`
- [ ] Test release builds on actual devices
- [ ] Prepare app store metadata (descriptions, screenshots)
- [ ] Create privacy policy
- [ ] Set up crash reporting (Firebase Crashlytics, Sentry)
- [ ] Review and update security settings
- [ ] Test database migrations
- [ ] Verify backup/restore functionality

## Security Considerations

- **Keystore Security**: Never commit keystore files to version control
- **Database Encryption**: Uses Android Keystore for encryption key storage
- **Data Privacy**: All user data is stored locally on device
- **Backup Security**: Encrypted backup files with TTL management

## Contributing

Contributions are welcome! Please follow these guidelines:
- Write tests for new features
- Follow existing code style
- Update documentation as needed
- Run tests before submitting PRs

## License

This project is private and proprietary. All rights reserved.

## Support

For issues, questions, or support, please contact the development team.