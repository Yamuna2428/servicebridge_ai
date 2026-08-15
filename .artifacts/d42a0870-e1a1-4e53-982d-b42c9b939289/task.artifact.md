# Phase 8K: Multimodal AI Issue Analysis Task List

- `[x]` Dependency Setup
    - `[x]` Add `speech_to_text` and `image_picker` to `pubspec.yaml`
    - `[x]` Run `flutter pub get`
- `[x]` AI Service Enhancement
    - `[x]` Update `analyzeIssue` to handle `Uint8List` image parts
    - `[x]` Refine system prompt for multimodal safety
- `[x]` UI - Voice Input
    - `[x]` Implement `SpeechToText` logic and permissions
    - `[x]` Add Microphone button to Analyzer input
- `[x]` UI - Camera Input
    - `[x]` Implement `ImagePicker` logic
    - `[x]` Add Camera/Gallery trigger button
    - `[x]` Create Image Preview widget with Remove/Retake options
- `[x]` Final Verification
    - `[x]` Run `flutter analyze`
    - `[x]` Test Voice -> Text conversion
    - `[x]` Test Image + Text analysis
    - `[x]` Verify safety escalation for dangerous images
