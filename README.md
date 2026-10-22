# Zapcut

Zapcut is a simple Flutter video editor for choosing a video from the gallery,
previewing it, trimming its start and end, and saving the edited clip back to
the device.

## Build an Android APK with GitHub Actions

1. Download and extract this project ZIP into a new GitHub repository. Keep
   `.github/workflows/build-android-apk.yml` at the repository root.
2. Push the files to GitHub.
3. Open the repository's **Actions** tab, choose **Build Android APK**, and
   select **Run workflow**. The workflow also runs automatically for pushes
   and pull requests.
4. When it finishes, open the run and download the
   **zapcut-release-apk** artifact. The APK is inside that download at
   `app-release.apk`.

No Android SDK, signing key, or paid cloud build account is needed to run this
workflow. The APK is debug-signed for testing and sideloading; publishing on
Google Play requires configuring a release signing key separately.

## Build locally

Install Flutter and the Android SDK, then run:

```sh
flutter pub get
flutter build apk --release
```

The APK is written to
`build/app/outputs/flutter-apk/app-release.apk`.

## Requirements

- Flutter stable (Dart 3.8 or newer)
- Android device or emulator for running the app

Video selection, playback, trimming, and saving to the gallery use native
Android/iOS plugins. The web build is for preview and does not export trimmed
videos.
