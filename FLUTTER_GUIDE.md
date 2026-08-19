# ABC Pharmacy — Flutter Android App (Offline)

A native Android app built with **Flutter/Dart**. All data — medicines and
sales — is stored **entirely on the phone** in a local SQLite database. No
backend server, no Wi-Fi, no PC required to use the app once it's installed.

Same features as the web/API version: medicine grid with expiry/low-stock
color coding, add/edit/delete, sell (records a sale + deducts stock), sales
log, search.

## 1. What's changed

- **Photo scan → autofill**, described below.
- Everything else (SQLite local storage, no server needed) is the same as
  the previous offline version.

Tap **"Scan medicine photo"** in the Add/Edit dialog, take a photo of the
medicine strip/box (or pick one from the gallery), and the app:

1. Saves the photo permanently on-device (shown as a thumbnail on the
   medicine's card in the list from then on).
2. Runs **on-device OCR** (Google ML Kit text recognition — no internet
   needed after the first install) to read text off the photo.
3. Filters out obvious noise (batch numbers, MRP, dates, "Tablets",
   "Storage instructions", etc.) and takes its best guess at which lines
   are the product name vs. the brand, pre-filling those two fields.
4. Shows the other detected lines underneath — tap **"Name"** or
   **"Brand"** next to any of them to use that line instead, if the guess
   was wrong.

**Be upfront with yourself (and in the interview) about the limits here:**
there's no reliable way to know from text alone which printed line is
"the product name" vs "the brand" vs "the company" — different medicine
packaging puts these in different places, sizes, and orders. This feature
gives a reasonable first guess and a fast way to correct it, not a
guaranteed-accurate extraction. OCR quality also depends heavily on photo
lighting/focus/angle.

**One-time internet requirement:** Google ML Kit's on-device model downloads
via Google Play Services the first time text recognition runs after
install. After that first download, scanning works fully offline. If a
device has no Play Services at all (rare — mainly some tablets or emulator
images without Google apps), scanning won't work; typing details in
manually always still works regardless.

## 3. What's in this project

```
pharmacy_app_flutter/
├── pubspec.yaml              # sqflite, path_provider, image_picker, google_mlkit_text_recognition, intl, flutter_launcher_icons
├── lib/
│   ├── main.dart             # App entry + theme
│   ├── models/                 medicine.dart (now includes imagePath), sale.dart
│   ├── services/
│   │   ├── database_service.dart      # All local SQLite reads/writes
│   │   ├── ocr_service.dart           # ML Kit text recognition + noise filtering
│   │   └── photo_storage_service.dart # Saves picked photos into permanent app storage
│   ├── screens/                 home_screen.dart, sales_log_screen.dart
│   └── widgets/                  medicine_tile.dart (thumbnail), add_edit_medicine_dialog.dart (scan UI), sell_dialog.dart
├── assets/icon/                ABC Pharmacy launcher icon source images
└── .github/workflows/
    └── build-apk.yml           # Builds a ready-to-install .apk in the cloud
```

There's **no `android/` folder committed** — it's regenerated automatically
by `flutter create` (locally) or by the GitHub Actions workflow (in the
cloud), same as before.

## 4. How data storage works

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

**Upgrading from the previous offline version:** the database migration
code (`onUpgrade` in `database_service.dart`) is written to add the new
column in place without losing data — but that only works if Android treats
it as an *update* to the same app, which requires the new APK to be signed
with the same key as the old one. Since each GitHub Actions run generates a
fresh debug signing key by default, an APK built by a **different workflow
run** usually won't install as an update — Android will ask you to
uninstall the old app first (and you'll lose its data, since it's a fresh
app from Android's point of view). Building locally on the same machine each
time reuses the same debug keystore, so in-place updates work as described
there. If in-place updates matter for the cloud-build path too, the fix is
to generate a debug keystore once and cache it as a GitHub Actions secret —
happy to set that up if you want it.

## 5. Easiest path: get a ready `.apk` with no local install

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

## 6. Local path: build it yourself with Flutter installed

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

## 7. If you ever want the two versions to talk to each other later

Right now this is a fully standalone, single-device app — good for personal
use or a demo, but it doesn't share data between the web app and the phone,
or between two phones. If that becomes a requirement, the natural next step
is re-introducing a sync layer (e.g. periodically pushing/pulling changes to
the ASP.NET Core API, or swapping SQLite for a cloud-hosted database like
Firebase/Supabase) rather than reverting to "phone always talks to server
for every action" — happy to help design that when/if you need it.
