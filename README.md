# Digital Khata

Credit ledger (udhaar) for small shops with one-tap payment reminders. Flutter, GetX, offline-first.
Built from `Digital-Khata-Complete-Project-Documentation.md` (Hexovate Solutions, v1.0).

## Run it

```bash
./setup.sh      # flutter create (android+ios), native patches, pub get, analyze, test
flutter run
```

Requires Flutter 3.27 or newer. `setup.sh` never touches `lib/`, `test/` or `pubspec.yaml`.
`python3 tool/check_project.py` checks translation keys (en + ur), imports and Dart syntax without the SDK.

## What is implemented

| Feature | Status |
|---|---|
| F1 App lock + shop profile (PIN, biometric, auto-lock after 60 s, 5-try cooldown) | done |
| F2 Customers: add, edit, search, filter, sort, archive, import from contacts | done |
| F3 Credit / payment entries with date, note, bill photo, undo delete | done |
| F4 Running balance and dated ledger timeline | done |
| F5 One-tap reminder: WhatsApp (wa.me) or SMS, 3 templates, editable | done |
| F6 English / Urdu (RTL), switchable at runtime, bundled Inter + Noto Nastaliq | done |
| F7 Dashboard: receivable, today's collection, top 5 debtors, recent activity | done |
| F8 PDF statement for a date range, preview + share | done |
| F9 Backup / restore | **local JSON file** (works offline, share to Drive). Supabase cloud sync not wired |
| F10 Free plan limit (50 active customers, BR-06) | limit enforced; purchase button shows "coming soon" (needs Play Console products) |

Business and validation rules BR-01..BR-06 and VR-01..VR-05 live in `features/*/domain` and are unit tested.

## Deliberate deviations from the document

- **sqflite instead of Drift, hand-written models instead of freezed, GetX `Translations` instead of ARB.**
  These avoid `build_runner` / `gen-l10n` code generation, so the project builds with no generated files.
  The schema matches the data dictionary (integer paisa, UUIDs, soft delete, `sync_status`), so a sync engine can be added later.
- **No Supabase / Crashlytics / in_app_purchase** yet: each needs your own keys or console setup and would crash the app without them.
  `CrashReporter` (core/errors/failure.dart) is the single hook for Crashlytics.
- PDF labels are English; Urdu customer names fall back to the Nastaliq font (no complex shaping in the `pdf` package).
- Buttons are 48 dp high (touch-target rule) rather than 46.

## Crash-safety measures

Global `FlutterError` / `PlatformDispatcher` / zone handlers; boot-failure screen with Retry; every user action goes through `guard()`;
all writes are SQLite transactions; malformed rows are skipped, never thrown; restore validates the whole file first, backs up current data, and rolls back on any error;
biometric, keystore, contacts, camera and URL launching are wrapped so a failure falls back to PIN or a message; text controllers live in `State` objects (no use-after-dispose).

## Verification status

This was written in a sandbox with no Flutter SDK, so it has **not** been compiled or run on a device.
Syntax was verified with a Dart parser and `tool/check_project.py`. Run `./setup.sh` first and send me any analyzer output.
