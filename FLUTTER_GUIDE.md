# ABC Pharmacy — Flutter Android App (Offline)

A native Android app built with **Flutter/Dart**. All data — medicines and
sales — is stored **entirely on the phone** in a local SQLite database. No
backend server, no Wi-Fi, no PC required to use the app once it's installed.

Same features as the web/API version: medicine grid with expiry/low-stock
color coding, add/edit/delete, sell (records a sale + deducts stock), sales
log, search.

## 1. What's in this project

```
pharmacy_app_flutter/
├── pubspec.yaml              # Dependencies: sqflite, path, uuid, intl, flutter_launcher_icons
├── lib/
│   ├── main.dart             # App entry + theme
│   ├── models/                 medicine.dart, sale.dart
│   ├── services/
│   │   └── database_service.dart   # All local SQLite reads/writes (was api_service.dart)
│   ├── screens/                 home_screen.dart, sales_log_screen.dart
│   └── widgets/                  medicine_tile.dart, add_edit_medicine_dialog.dart, sell_dialog.dart
├── assets/icon/                ABC Pharmacy launcher icon source images
└── .github/workflows/
    └── build-apk.yml           # Builds a ready-to-install .apk in the cloud
```

There's **no `android/` folder committed** — it's regenerated automatically
by `flutter create` (locally) or by the GitHub Actions workflow (in the
cloud), same as before.

## 2. How data storage works now

- **`lib/services/database_service.dart`** opens (and creates, on first
  launch) a SQLite database file called `pharmacy.db` inside the app's
  private storage on the phone, using the `sqflite` package.
- Two tables: `medicines` and `sales` — same fields as the original
  ASP.NET Core models.
- **First launch seeds 6 sample medicines** (same ones the web version
  shipped with), so the app isn't empty out of the box.
- **Selling a medicine** runs inside a database transaction: check stock →
  deduct quantity → insert the sale row, all or nothing — same rule the API
  used to enforce, just enforced locally now.
- Uninstalling the app deletes its data (normal Android behavior for local
  app storage). There's no sync/backup built in — if you need that later
  (e.g. export to a file, or sync across devices), that's a separate
  feature to add.

**`config.dart` and `api_service.dart` are gone** — there's no server URL to
configure anymore.

## 3. Easiest path: get a ready `.apk` with no local install

Same GitHub Actions approach as before:

1. Push/upload this updated project to your existing GitHub repo (replacing
   the old files) — or create a new repo if you'd rather keep the old
   network-based version around separately.
2. Go to the **Actions** tab — "Build Flutter Android APK" runs
   automatically, takes a few minutes.
3. Download the **`ABCPharmacy-flutter-debug-apk`** artifact from the
   finished run, unzip it, and you'll have `app-debug.apk`.
4. Send it to your phone, tap to open, allow "install unknown apps", install.

No config file to edit this time — the app works immediately after install,
no network setup needed.

## 4. Local path: build it yourself with Flutter installed

```bash
cd pharmacy_app_flutter
flutter create --platforms=android --org com.abcpharmacy --project-name pharmacy_app_flutter .
flutter pub get
dart run flutter_launcher_icons
flutter run              # installs on a connected device/emulator directly
# or
flutter build apk --debug
```

The APK lands at `build/app/outputs/flutter-apk/app-debug.apk`.

## 5. If you ever want the two versions to talk to each other later

Right now this is a fully standalone, single-device app — good for personal
use or a demo, but it doesn't share data between the web app and the phone,
or between two phones. If that becomes a requirement, the natural next step
is re-introducing a sync layer (e.g. periodically pushing/pulling changes to
the ASP.NET Core API, or swapping SQLite for a cloud-hosted database like
Firebase/Supabase) rather than reverting to "phone always talks to server
for every action" — happy to help design that when/if you need it.
