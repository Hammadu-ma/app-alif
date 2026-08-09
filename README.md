# Alif Med — Flutter WebView App

A lightweight Flutter wrapper for **alifmeta.vercel.app**, built to feel like a real native app rather than "a website in a box":

- Modern WebView with pull-to-refresh
- Branded splash/loading screen matching the site's theme (`#F4F7F5`, monogram mark)
- Native progress bar during page loads
- Offline / connection-error screens with a Retry button
- Android back button navigates within the site (not straight out of the app)
- Fast startup, minimal dependencies

This is a **complete Flutter project source** — not a compiled app — because building an actual `.apk`/`.ipa` requires the Flutter SDK, Android SDK (and a Mac + Xcode for iOS), which aren't available in this environment. Below is exactly how to turn it into an installable app in a few minutes.

## What's included
```
alif_meta_app/
├── lib/main.dart          ← all app logic (webview, splash, error/offline states)
├── pubspec.yaml            ← dependencies + icon/splash config
├── assets/
│   ├── app_icon.png        ← placeholder app icon (replace with your real logo)
│   └── splash_logo.png     ← placeholder splash mark
└── android/                ← full, ready-to-build Android project
```
iOS platform files aren't included (a valid Xcode project can't be hand-authored safely) — see step 4 to add iOS support in one command.

## 1. Install Flutter
If you don't already have it: https://docs.flutter.dev/get-started/install
Verify with:
```
flutter doctor
```

## 2. Set your local SDK path
Open `android/local.properties` and set:
```
sdk.dir=/path/to/your/Android/sdk
flutter.sdk=/path/to/your/flutter
```
(Android Studio fills this in automatically if you open the project there instead.)

## 3. Get packages
```
cd alif_meta_app
flutter pub get
```

## 4. (Optional) Add iOS support
```
flutter create --platforms=ios .
```
This only adds the missing `ios/` folder — it won't touch your `lib/`, `pubspec.yaml`, or `android/`.

## 5. Swap in your real icon and splash image
Replace `assets/app_icon.png` (1024×1024, no transparency for Android) and `assets/splash_logo.png` (transparent PNG) with your actual logo, then run:
```
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

## 6. Run it
```
flutter run
```

## 7. Build a release APK
```
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

For the Play Store, build an app bundle instead, and add a real signing config in `android/app/build.gradle` first (currently signed with the debug key as a placeholder):
```
flutter build appbundle --release
```

## Changing the URL
Everything points at one constant near the top of `lib/main.dart`:
```dart
const String kAppUrl = 'https://alifmeta.vercel.app';
```

## Fixed: Codemagic trying to build iOS too (and failing)
Codemagic's default workflow builds both Android and iOS. Since this project has no `ios/` folder, that step fails with `Did not find xcodeproj`, even though the Android build itself succeeds. A `codemagic.yaml` is now included at the project root that defines an **Android-only** workflow. On Codemagic, go to your app → **Workflow editor** → switch from the default workflow to **"Alif Med - Android"** (it's auto-detected from this file) → Start new build.

## Fixed: Gradle version build error
An earlier version of this project didn't pin a Gradle wrapper version, which caused newer Flutter releases to fail with:
```
Your project's Gradle version (8.4.0) is lower than Flutter's minimum supported version of 8.7.0
```
This is now fixed — `android/gradle/wrapper/gradle-wrapper.properties` pins Gradle 8.9, and `android/build.gradle` / `android/settings.gradle` use AGP 8.7.3 with Kotlin 2.1.0, a known-compatible combination. If you re-run the build (locally or on Codemagic), it should now complete.

## Notes
- App ID is `com.alifmed.app` — change it in `android/app/build.gradle` (`applicationId`) and the Kotlin package path before publishing if you want something else.
- `usesCleartextTraffic` is `false`, since your site is served over HTTPS — no change needed unless you add non-HTTPS content.
