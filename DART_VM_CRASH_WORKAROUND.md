# 🚨 Dart VM Crash - Workaround Instructions

## Issue

The app is crashing during Dart VM initialization with an assertion failure:
```
dart::Assert::Fail(char const*, ...) const
dart::Dart::DartInit(Dart_InitializeParams const*)
```

This is a **Flutter engine-level crash** happening before your app code runs.

## Immediate Workarounds

### Option 1: Test on iOS Simulator (Recommended)

```bash
# List available simulators
flutter devices

# Run on simulator
cd /Users/macbook/StudioProjects/video_player_m3u8_alerts/example
flutter run lib/waveform_demo.dart -d "iPhone 15 Pro"
```

Simulators often work when physical devices crash due to different build configurations.

### Option 2: Open in Xcode for Better Debugging

```bash
cd /Users/macbook/StudioProjects/video_player_m3u8_alerts/example/ios
open Runner.xcworkspace
```

In Xcode:
1. Select your device
2. Select Runner scheme
3. Product > Clean Build Folder (Cmd+Shift+K)
4. Product > Run (Cmd+R)
5. Check Console for detailed error messages

### Option 3: Downgrade Flutter (If Needed)

This crash pattern is sometimes related to Flutter 3.24+ with certain iOS versions.

```bash
# Check current version
flutter --version

# If on bleeding edge, switch to stable
flutter channel stable
flutter upgrade

# Clean and rebuild
cd /Users/macbook/StudioProjects/video_player_m3u8_alerts/example
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

## Potential Causes

### 1. Flutter Engine Mismatch
- Your Flutter might be on an unknown channel
- Engine version might be incompatible with iOS

### 2. Architecture Issues
- Physical device might require different build settings
- Simulator uses x86_64/arm64 (Mac architecture)
- Physical device uses pure arm64

### 3. Code Signing Issues
- Even though build succeeds, runtime signing might fail
- Check Xcode > Signing & Capabilities

## Recommended Steps (In Order)

### Step 1: Try Simulator

```bash
cd /Users/macbook/StudioProjects/video_player_m3u8_alerts/example

# Start simulator
open -a Simulator

# Run app
flutter run lib/waveform_demo.dart
```

### Step 2: Fix Flutter Channel

```bash
flutter channel stable
flutter upgrade
flutter doctor -v
```

### Step 3: Clean Everything

```bash
cd /Users/macbook/StudioProjects/video_player_m3u8_alerts/example

# Clean Flutter
flutter clean

# Clean iOS
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec

# Rebuild
flutter pub get
cd ios && pod install && cd ..
```

### Step 4: Build from Xcode

```bash
cd ios
open Runner.xcworkspace
```

Then build and run from Xcode to see detailed errors.

## Alternative: Use Android for Testing

If iOS continues to crash:

```bash
# Run on Android
flutter run lib/waveform_demo.dart -d <android-device-id>
```

The waveform slider will work identically on Android.

## What Works

✅ **Build** - The iOS build completes successfully  
✅ **Installation** - App installs on device  
❌ **Runtime** - Dart VM fails to initialize  

This suggests the issue is **not in your code** but in the Flutter/iOS runtime configuration.

## Debug Information to Collect

If you want to report this:

1. **Flutter version:**
```bash
flutter --version
```

2. **iOS version:**
Check Settings > General > About on your iPhone

3. **Xcode version:**
```bash
xcodebuild -version
```

4. **CocoaPods version:**
```bash
pod --version
```

## Summary

**Immediate action**: Try running on **iOS Simulator** instead of physical device.

```bash
cd /Users/macbook/StudioProjects/video_player_m3u8_alerts/example
open -a Simulator
flutter run lib/waveform_demo.dart
```

The simulator often works when physical devices crash with Dart VM issues. This will let you test the waveform slider functionality while we investigate the physical device crash. 📱

