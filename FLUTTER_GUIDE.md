# ABC Pharmacy — Flutter Android App

A native Android app built with **Flutter/Dart**, talking to the same
ASP.NET Core API as the web version (`PharmacyApp.zip`). Same features:
medicine grid with expiry/low-stock color coding, add/edit/delete, sell
(records a sale + deducts stock), sales log, search.

**This app needs the API running somewhere reachable by the phone** — it's a
client only, same as the Capacitor version. Nothing about the backend
changes.

## 1. What's in this project

```
pharmacy_app_flutter/
├── pubspec.yaml              # Dependencies: http, intl, flutter_launcher_icons
├── lib/
│   ├── main.dart             # App entry + theme
│   ├── config.dart           # ← set your API server URL here
│   ├── models/                medicine.dart, sale.dart
│   ├── services/               api_service.dart (all HTTP calls)
│   ├── screens/                home_screen.dart, sales_log_screen.dart
│   └── widgets/                 medicine_tile.dart, add_edit_medicine_dialog.dart, sell_dialog.dart
├── assets/icon/               ABC Pharmacy launcher icon source images
└── .github/workflows/
    └── build-apk.yml          # Builds a ready-to-install .apk in the cloud
```

There's **no `android/` folder committed** — it's regenerated automatically
(by `flutter create` or by the GitHub Actions workflow) since it's large,
machine-specific, and doesn't need to be hand-maintained.

## 2. Easiest path: get a ready `.apk` with no local install (recommended)

This is the same approach used for the Capacitor version — GitHub Actions
builds the APK in the cloud, you just download it.

1. Create a free GitHub account at github.com if you don't have one.
2. Create a new repository (github.com/new), keep it Public.
3. Upload every file/folder from this `pharmacy_app_flutter/` project
   (drag-and-drop on the repo page, or use GitHub Desktop so hidden folders
   like `.github/` come along correctly).
4. Go to the **Actions** tab — "Build Flutter Android APK" starts
   automatically. It takes a few minutes (Flutter's first build downloads
   its SDK and Gradle dependencies).
5. When it finishes (green check), open that workflow run → **Artifacts** →
   download `ABCPharmacy-flutter-debug-apk`. Unzip it — that's your
   `app-debug.apk`.
6. Send it to your phone (WhatsApp/Drive/email), tap to open, allow "install
   unknown apps" when prompted, install.

**Before you upload:** open `lib/config.dart` and set `apiBaseUrl` to
wherever your ASP.NET Core API will be reachable from your phone — usually
your PC's LAN IP while testing (e.g. `http://192.168.1.42:5080`), found via
`ipconfig`. Your phone and the PC running the API need to be on the same
Wi-Fi when you actually use the app.

## 3. Local path: build it yourself with Flutter installed

If you'd rather build on your own machine:

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install)
   and Android Studio (for the Android SDK + an emulator).
2. `cd pharmacy_app_flutter`
3. Generate the native Android project (this fills in `android/` without
   touching your `lib/` code):
   ```bash
   flutter create --platforms=android --org com.abcpharmacy --project-name pharmacy_app_flutter .
   flutter pub get
   dart run flutter_launcher_icons
   ```
4. Open `android/app/src/main/AndroidManifest.xml` and add
   `android:usesCleartextTraffic="true"` to the `<application ...>` tag
   (needed because the dev API runs on plain `http://`, which Android
   blocks by default).
5. Edit `lib/config.dart` with your API server URL (see above).
6. Run it:
   ```bash
   flutter run          # installs on a connected device/emulator directly
   # or, for just the APK file:
   flutter build apk --debug
   ```
   The APK lands at `build/app/outputs/flutter-apk/app-debug.apk`.

## 4. Notes on what's set up

- **State management** is plain `StatefulWidget` + `setState` — no
  Provider/Riverpod/Bloc — since the screen count is small (list, sales log,
  two dialogs). Fine here; if the app grew, I'd reach for a state management
  package to avoid prop-drilling.
- **`ApiService`** mirrors the same endpoints as the web app
  (`/api/medicines`, `/api/sales`) and throws a typed `ApiException` with the
  server's error message on failure, which the UI surfaces via `SnackBar`s
  and inline dialog errors.
- **Color coding** (`Medicine.isExpiringSoon`, `Medicine.isLowStock`) mirrors
  the same thresholds as the web app (30 days, 10 units) — kept in the model
  so both the list tile and any future screen can reuse the same logic.
- **Debug build only.** This is signed with Flutter's default debug key —
  fine for testing/sideloading on your own devices. A Play Store release
  needs your own signing key, which is a separate step I'm happy to help
  with if you get there.
