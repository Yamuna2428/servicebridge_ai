# Implementation Plan - Phase 8K Android Build Fix

This plan addresses the Android build failure encountered in the `speech_to_text` package during Phase 8K.

## Root Cause Analysis
The build failure (`Unresolved reference 'Registrar'`, etc.) is caused by a compatibility mismatch between `speech_to_text: ^6.6.2` and the project's modern Android environment:
- **Flutter**: 3.44.8
- **Kotlin**: 2.2.20
- **Android Gradle Plugin (AGP)**: 8.11.1

The errors indicate that the plugin is attempting to use deprecated Android V1 embedding components which are no longer supported or correctly resolved in the current high-version Kotlin/AGP setup.

## Proposed Changes

### [Dependencies]

#### [MODIFY] [pubspec.yaml](file:///C:/Users/yamun/StudioProjects/servicebridge_ai/pubspec.yaml)
- Upgrade `speech_to_text` from `^6.6.2` to `^7.4.0`. This version is explicitly designed for better compatibility with newer Flutter and Android environments.

## Verification Plan

### Automated Tests
1. **Clean & Resolve**:
   - `flutter clean`
   - `flutter pub get`
2. **Static Analysis**:
   - `flutter analyze` (Ensure no API breaks in `ai_issue_analyzer_screen.dart`)
3. **Build APK**:
   - `flutter build apk --debug` (Confirm the Kotlin compilation errors are resolved)

### Manual Verification
- Launch the application on an emulator.
- Navigate to the **AI Issue Analyzer**.
- Verify that the **Microphone** button still:
    - Requests permissions.
    - Successfully transcribes speech to text.
    - Allows editing of the text.
    - Does not automatically submit the request.
