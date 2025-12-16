# 🔧 iOS Crash Fix

## Issue

The app was crashing on iOS during Dart VM initialization with assertion failure.

## Fixes Applied

### 1. Added Required iOS Permissions

**File**: `example/ios/Runner/Info.plist`

Added:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
<key>io.flutter.embedded_views_preview</key>
<true/>
```

**Why**: Required for:
- Network video playback (M3U8 streams)
- Platform views (video player)

### 2. Set iOS Platform Version

**File**: `example/ios/Podfile`

Changed:
```ruby
# platform :ios, '12.0'  # Commented out
```

To:
```ruby
platform :ios, '12.0'  # Enabled
```

**Why**: Video player requires minimum iOS 12.0

### 3. Created Simple Test App

**File**: `example/lib/simple_test.dart`

A minimal Flutter app to verify basic functionality before testing video features.

## Steps to Fix

### 1. Clean Build

```bash
cd example

# Clean Flutter build
flutter clean

# Clean iOS build
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec
cd ..
```

### 2. Reinstall Dependencies

```bash
# Get Flutter dependencies
flutter pub get

# Install iOS pods
cd ios
pod install --repo-update
cd ..
```

### 3. Test Simple App First

```bash
# Test with simple app
flutter run lib/simple_test.dart
```

If this works, proceed to waveform demo:

```bash
flutter run lib/waveform_demo.dart
```

## Alternative: Run from Xcode

1. Open `example/ios/Runner.xcworkspace` in Xcode
2. Select your device
3. Product > Clean Build Folder (Cmd+Shift+K)
4. Product > Run (Cmd+R)

This gives you better error messages if there are still issues.

## Common iOS Issues

### Issue 1: Development Team Not Set

**Fix in Xcode:**
1. Select Runner project
2. Go to Signing & Capabilities
3. Select your Team

### Issue 2: Provisioning Profile

**Fix:**
```bash
# In Xcode, go to:
# Product > Clean Build Folder
# Then try running again
```

### Issue 3: CocoaPods Issues

**Fix:**
```bash
cd example/ios
pod deintegrate
pod install
cd ..
```

## Verify Info.plist

Your `Info.plist` should now contain:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
<key>io.flutter.embedded_views_preview</key>
<true/>
```

## Run Commands

```bash
cd /Users/macbook/StudioProjects/video_player_m3u8_alerts/example

# Clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock

# Reinstall
flutter pub get
cd ios && pod install && cd ..

# Test simple app
flutter run lib/simple_test.dart

# Then test waveform demo
flutter run lib/waveform_demo.dart
```

## If Still Crashing

1. **Check Xcode Console** - Open Xcode and look for detailed error messages
2. **Update Flutter** - Run `flutter upgrade`
3. **Check Device Logs** - Xcode > Window > Devices and Simulators > View Device Logs
4. **Try Simulator First** - Test on iOS Simulator before physical device

## Summary

✅ Added NSAppTransportSecurity for network video  
✅ Enabled platform views for video player  
✅ Set minimum iOS version to 12.0  
✅ Created simple test app  
✅ Provided clean build commands  

Try the clean build process above and the app should launch successfully!

