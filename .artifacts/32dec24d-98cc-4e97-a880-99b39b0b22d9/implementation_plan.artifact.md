# Implementation Plan - Phase 1: Stability & Verification

Audit, compile, and verify the navigation flow of the ServiceBridge AI Flutter application to ensure a stable foundation.

## User Review Required

> [!IMPORTANT]
> The focus is purely on stabilization and verification. No new features or Firebase integration will be performed.

- **Navigation Verification**: Confirming all paths between Splash, User Type, Auth, and Home screens are functional in the code.
- **Environment Constraints**: Note that while the code is verified, the Gradle build environment in the agent shell might still face permission issues (e.g., `AndroidLocationsBuildService`). I will attempt to diagnose this without making destructive changes.

## Proposed Changes

### Audit & Stability (Tasks 1-3)

- **Manual Code Audit**: Review all screen files for import consistency and correct usage of models/widgets.
- **Flutter Analyze**: Run `flutter analyze` to ensure 0 errors/warnings.
- **Dependency Check**: Run `flutter pub get` to sync dependencies.

### Navigation Logic (Task 4)

#### [VERIFY] [main.dart](file:///C:/Users/yamun/StudioProjects/servicebridge_ai/lib/main.dart)
- `initialRoute` points to `SplashScreen`.
- Named routes are correctly defined.

#### [VERIFY] [login_screen.dart](file:///C:/Users/yamun/StudioProjects/servicebridge_ai/lib/screens/login_screen.dart)
- Role-based navigation to `WorkerHomeScreen` or `CustomerHomeScreen`.
- "Continue as Guest" flow.

#### [VERIFY] [Profile Screens](file:///C:/Users/yamun/StudioProjects/servicebridge_ai/lib/screens/customer_profile_screen.dart)
- Logout flow returning to the Splash screen.

### Execution (Task 5)

- **Run on Emulator**: Attempt to launch the app on the Pixel 8 emulator using `flutter run`.
- **Diagnostics**: If the build fails due to Gradle environment issues, I will identify the exact cause (e.g., directory permissions) and report it rather than modifying the Android project structure destructively.

## Verification Plan

### Automated Tests
- `flutter analyze` must return "No issues found!".

### Manual Verification (Code Review)
- Trace `Navigator` calls in all screens to ensure they match the user's flow requirements.
- Verify `userType` prop propagation from `UserTypeScreen` down to `SignUpScreen`.
