# Build APK Plan

## Goal
Clean the workspace, run package resolution, and build the release APK.

## Tasks
- [x] Task 1: Find and delete any existing APK files in the project workspace → Verify: No `.apk` files exist in `build/` or under `android/`
- [x] Task 2: Run `flutter clean` to clear build caches → Verify: Command completes successfully and `build/` directory is removed
- [x] Task 3: Run `flutter pub get` to fetch dependencies → Verify: Command completes successfully
- [x] Task 4: Run `flutter build apk --release` (or default apk build) → Verify: Build completes successfully and outputs an APK
- [x] Task 5: Identify and display the full path to the newly built APK file → Verify: APK file exists at the path and can be shared

## Done When
- [x] Clean and build execute without errors
- [x] The full path of the new APK is displayed to the user
