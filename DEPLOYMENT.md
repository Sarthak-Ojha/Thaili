# Thaili Deployment Guide

This guide covers the deployment process for the Thaili finance management application.

## Deployment Strategy

**Current Focus**: Windows desktop application (free distribution via personal website)
**Future Expansion**: Android (Google Play Store), iOS (App Store)

## Prerequisites

### For Windows Deployment (Current Focus)
- Windows 10 or later development machine
- Visual Studio Community 2022 with "Desktop development with C++" workload
- Flutter SDK 3.13.0 or higher
- Personal website or hosting for file distribution

### For Android Deployment (Future)
- Android Studio installed
- Java Development Kit (JDK) 17
- Android SDK with latest platform tools
- Production keystore file (see below)
- Google Play Developer account ($25 one-time fee)

### For iOS Deployment (Future)
- macOS development machine
- Xcode installed
- Apple Developer account ($99/year)
- Code signing certificates
- Provisioning profiles

## Windows Deployment

### 1. Build Setup

Ensure Visual Studio is installed with the "Desktop development with C++" workload:

```bash
# Check Flutter doctor
flutter doctor

# Should show Visual Studio as [√]
```

### 2. Building Windows Release

```bash
# Build Windows release executable
flutter build windows --release

# Output location: build/windows/x64/runner/Release/thaili.exe
```

### 3. Testing the Build

Before distribution, test the executable:

```bash
# Run the built executable
build/windows/x64/runner/Release/thaili.exe
```

Test critical functionality:
- Database initialization
- Data persistence across restarts
- All core features work correctly
- No obvious bugs or crashes

### 4. Packaging for Distribution

> [!IMPORTANT]
> A Flutter Windows application consists of `thaili.exe`, dependent DLLs (`flutter_windows.dll`, plugin DLLs, `sqlite3.dll`), and the `data/` directory. `thaili.exe` **cannot** be distributed alone. You must distribute either the zipped bundle or an installer.

#### Option A: 1-Click Automated Packaging (Recommended)
Run the automated packaging script from PowerShell:
```powershell
.\package_windows.ps1
```
This runs tests, compiles the release build, and outputs:
- Portable ZIP: `dist/Thaili-v1.0.0-Windows-Portable.zip`
- Setup Installer: `dist/ThailiSetup-v1.0.0.exe` (if Inno Setup is installed)

#### Option B: Portable ZIP Archive (Free & Zero-Install)
Users simply extract the ZIP and run `thaili.exe`. No administrator privileges needed.
```powershell
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "dist\Thaili-v1.0.0-Windows-Portable.zip"
```

#### Option C: Inno Setup Installer (.exe Wizard)
For a professional installer wizard with Desktop shortcut, Start Menu entry, and clean uninstaller:
1. Install Inno Setup (free): `winget install JRSoftware.InnoSetup`
2. Compile the installer:
```powershell
iscc windows_installer.iss
```
Output: `dist/ThailiSetup-v1.0.0.exe`

### 5. Website Distribution

**Hosting on Personal Website:**

1. **Upload Files:**
   - Upload the EXE or ZIP file to your website
   - Create a dedicated download page
   - Use the provided HTML template (website-download-page.html)

2. **File Structure:**
   ```
   sarthakojha.com.np/
   ├── downloads/
   │   └── thaili.exe (or thaili.zip)
   └── thaili-download.html (download page)
   ```

3. **Download Page:**
   - Use the provided HTML template
   - Customize with your branding
   - Include version information and system requirements
   - Add security note about "Unknown Publisher" warning

### 6. Version Management

**Version Numbering:**
- Update version in `pubspec.yaml`: `version: 1.0.0+1`
- Update download page with new version info
- Keep previous versions available if needed

**Update Distribution:**
- Build new version with updated version number
- Upload new file to website
- Update download page with new version info
- Notify users of updates (add in-app update check later)

### 7. Security Considerations

**Code Signing (Optional):**
- Currently not code-signed (costs $200-400/year)
- Users will see "Unknown Publisher" warning
- Add note on download page about this
- Consider code signing when budget allows

**File Security:**
- Scan executable for viruses before distribution
- Host on secure HTTPS server (your site already has SSL)
- Monitor for any security reports

### 8. User Support

**Provide Support Channels:**
- Email contact on download page
- FAQ section for common issues
- Bug reporting mechanism
- Feature request system

**Common Issues to Address:**
- Windows security warnings
- Installation problems
- Data import/export
- Crash reporting

## Android Deployment (Future)

### 1. Keystore Management

The application uses a production keystore for signing release builds. 

**Important Security Notes:**
- Never commit keystore files to version control
- Store keystore files in a secure location
- Keep multiple backups of keystore files
- Document keystore passwords securely
- If keystore is lost, you cannot update your app on Play Store

**Current Keystore Configuration:**
- Keystore file: `android/thaili-release.keystore`
- Key alias: `thaili-key-alias`
- Keystore password: (stored in `android/key.properties`)
- Key password: (stored in `android/key.properties`)
- Package name: `com.sarthak.thaili`

### 2. Building Release APK

```bash
# Build release APK for testing/distribution
flutter build apk --release

# Output location: build/app/outputs/flutter-apk/app-release.apk
```

### 3. Building App Bundle for Play Store

```bash
# Build App Bundle for Google Play Store
flutter build appbundle --release

# Output location: build/app/outputs/bundle/release/app-release.aab
```

### 4. Google Play Store Submission

1. **Create Application**
   - Go to Google Play Console
   - Create new application
   - Fill in app details (name, description, etc.)

2. **Upload App Bundle**
   - Navigate to "Release" → "Production" (or testing track)
   - Upload the `.aab` file
   - Wait for Google to process

3. **Complete Store Listing**
   - Add app description (short and full)
   - Upload screenshots (at least 2, recommended 4-8)
   - Add app icon (512x512 high-res)
   - Add feature graphic (1024x500)
   - Set content rating

4. **Privacy Policy**
   - Create and upload privacy policy
   - Since app is offline-first, policy can be simple
   - Mention data storage (local only, encrypted)

5. **Content Rating**
   - Complete content rating questionnaire
   - Finance apps typically get "Everyone" or "Teen" rating

6. **Pricing & Distribution**
   - Set price (or free)
   - Select countries for distribution
   - Choose device compatibility

7. **Release**
   - Review all information
   - Submit for review
   - Wait for approval (typically 1-3 days)

## iOS Deployment

### 1. Code Signing Setup

1. **Create Apple Developer Account**
   - Sign up at developer.apple.com
   - Enroll in Apple Developer Program ($99/year)

2. **Create App ID**
   - Go to Apple Developer Portal
   - Create new App ID: `com.sarthak.thaili`
   - Enable required capabilities

3. **Create Provisioning Profile**
   - Create development profile for testing
   - Create distribution profile for App Store

4. **Configure Xcode**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select your team in Signing & Capabilities
   - Verify bundle identifier matches

### 2. Building iOS Release

```bash
# Build iOS release (requires macOS)
flutter build ios --release

# Archive in Xcode for App Store submission
open ios/Runner.xcworkspace
# Then: Product → Archive
```

### 3. App Store Submission

1. **Create App Record**
   - Go to App Store Connect
   - Create new app
   - Fill in app information

2. **Upload Build**
   - Use Xcode to upload archived build
   - Or use Transporter tool
   - Wait for processing

3. **Complete App Information**
   - Add screenshots (required for each device size)
   - Write app description
   - Add promotional text
   - Set keywords
   - Add support URL and privacy policy URL

4. **Submit for Review**
   - Choose pricing and availability
   - Submit for App Store review
   - Wait for approval (typically 1-2 weeks)

## Version Management

### Updating Version Numbers

1. **Update pubspec.yaml:**
```yaml
version: 1.0.1+2  # versionName+versionCode
```

2. **Build new release:**
```bash
flutter build apk --release
flutter build appbundle --release
```

3. **Submit to app stores with release notes**

### Versioning Strategy
- Major version (X.0.0): Major features, breaking changes
- Minor version (1.X.0): New features, backward compatible
- Patch version (1.0.X): Bug fixes, small improvements

## Post-Deployment Monitoring

### Crash Reporting
- Implement Firebase Crashlytics
- Set up error tracking
- Monitor crash rates

### Analytics
- Consider adding usage analytics (with user consent)
- Track key user flows
- Monitor app performance

### User Feedback
- Set up feedback mechanism
- Monitor app store reviews
- Respond to user issues promptly

## Troubleshooting

### Build Issues
```bash
# Clean build artifacts
flutter clean
cd android && ./gradlew clean
cd ..

# Update dependencies
flutter pub upgrade
```

### Signing Issues
- Verify keystore file exists
- Check key.properties configuration
- Ensure passwords are correct
- Verify keystore alias matches

### Store Submission Issues
- Check app store guidelines
- Ensure all required metadata is complete
- Verify screenshots meet specifications
- Check privacy policy is accessible

## Security Best Practices

1. **Keystore Management**
   - Store keystore in secure location
   - Use strong, unique passwords
   - Keep backups in multiple secure locations
   - Document recovery procedures

2. **Code Security**
   - Never hardcode API keys or secrets
   - Use environment variables for sensitive data
   - Enable code obfuscation for release builds
   - Regular security audits

3. **Data Protection**
   - Ensure database encryption is working
   - Test backup/restore functionality
   - Verify secure storage implementation
   - Regular security updates

## Emergency Procedures

### Keystore Loss
If keystore is lost:
- You cannot update existing app
- Must create new app with new package name
- Users will need to reinstall new app
- Previous app data will be lost

### Security Incident
1. Immediately investigate scope
2. Notify affected users if needed
3. Patch vulnerabilities quickly
4. Release security update
5. Document incident and response

## Contact Information

For deployment issues or questions:
- Development Team: [contact information]
- Emergency: [emergency contact procedure]

## Additional Resources

- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Android Signing Guide](https://developer.android.com/studio/publish/app-signing)