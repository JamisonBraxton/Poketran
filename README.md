# Pokétran — offline Pokémon team and training planner

**Status:** Source package, not a tested release APK. A Flutter SDK is required to compile and verify it. No cloud APIs or accounts are used.

Pokétran is a fan-made student productivity app to organize up to six Pokémon per team, save a personal training log, and get an explainable offline team-coach suggestion. All Pokémon data is entered on-device; no licensed sprites, PokeAPI, Firebase, or external backends are bundled. It is not affiliated with Pokémon's owners.

## Core features

1. **My teams / dashboard:** Search by name, goal, and region; filter by team status; see progress and counts.
2. **Create / edit forms:** Validate team names, goals, region, Pokémon species, type, role, level, and notes. Save member training percentages with a slider.
3. **Team details / activity:** View a six-slot roster, add/edit/release Pokémon, inspect the coach, and start/finish/reset a training journey with confirmation and safety checks.
4. **Insights / history:** See aggregate progress, type distribution, completed teams, and dated changes.
5. **Settings:** Toggle theme and coach visibility using `shared_preferences`; create an optional sample Kanto team.

The app adapts its main navigation: bottom navigation on narrow screens and a rail on wider screens. Status transitions use a short animation. All required features are on-device.

## Start on Windows with VS Code

1. Install the **Flutter SDK** and Android Studio (Android SDK + emulator). Add Flutter to your PATH. An Android phone is **not** required if you use an Android emulator. Windows desktop runs additionally need Visual Studio's C++ desktop workload, which is separate from VS Code.
2. Extract the ZIP, open the `Poketran` folder in VS Code, and run **`setup_windows.bat`**. It generates the platform-specific runner folders from your Flutter SDK, sets the Android launcher label to **Pokétran**, obtains dependencies, and attempts analysis and tests.
3. Start an Android emulator. In the integrated terminal, run:

   ```powershell
   flutter doctor
   flutter devices
   flutter run
   ```

4. Open **Settings > Create demo team**, then **Teams > Kanto Showcase**. Try the coach, status controls, member editor, and Insights.
5. When tests pass and the app runs, build a release APK:

   ```powershell
   flutter build apk --release
   ```

   The output is `build/app/outputs/flutter-apk/app-release.apk`. You must install and verify the built release before submission. An APK is **not included** in this ZIP.

**Manual generation (alternative to the batch file):**

```powershell
flutter create --project-name poketran --platforms=android,windows .
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/set_app_name.ps1
flutter pub get
flutter analyze
flutter test
flutter run
```

The project identifier is ASCII `poketran` because Dart package and native identifiers cannot contain accented letters. The visible application name is **Pokétran**. `flutter create` generates native Android/Windows boilerplate, so it is not shipped here; you can regenerate it as needed.

## GitHub upload and automatic checks

After creating an empty `Poketran` repository, upload the **contents** of this folder (not the ZIP as a single file). See `docs/GITHUB_UPLOAD.md` for exact PowerShell Git commands and web-upload instructions. A workflow in `.github/workflows/flutter.yml` generates the Android runner, runs Dart formatting checks, analyzes the app, runs tests, and attempts to build a release APK on GitHub Actions. **The workflow has not yet been executed and build success is not guaranteed.**

## Folder map

```text
Poketran/
  lib/main.dart                      app initialization and themed root
  lib/data/database_service.dart    SQLite version 2, transactions, two related entities
  lib/data/settings_store.dart      SharedPreferences settings store
  lib/logic/team_advisor.dart       deterministic coach, baseline, action types
  lib/pages/                      dashboard, editor, details, insights, settings
  lib/widgets/                    reusable UI and confirmation dialogs
  test/                           validation, database, widget, coach, settings tests
  AI_FEATURE.md                    required smart-helper explanation and evaluation
  AI_Usage_Log.md                  development assistance disclosure
  docs/ASSIGNMENT_AUDIT.md         requirements-to-evidence audit
  docs/ARCHITECTURE.md             data schema, routing and state
  docs/TEST_PLAN.md                real manual and automated verification plan
  docs/SUBMISSION_CHECKLIST.md     remaining artifacts to produce
  docs/PEER_TEST_TEMPLATE.md       before/after usability test template
  docs/SHOWCASE_OUTLINE.md         20–25-minute demo outline
  scripts/set_app_name.ps1         native display-name patch after flutter create
  setup_windows.bat                Windows bootstrap
  build_android_apk.bat            Android release build helper
```

## App workflow

1. Create a team with name, region, and goal.
2. Add one to six Pokémon with type, role, level, optional nickname and notes.
3. Start training. Move the training slider for each Pokémon and save it.
4. Review the team coach's **baseline** and its **suggestion / reason**. Choose **Apply** (opens a normal editor or workflow), **Not now** (persists dismissal), or **Reveal** (restores dismissed tips). Changing the roster recalculates suggestions.
5. Once all members reach 100%, finish the team. Reset to start a new journey.
6. View the activity and aggregates in Insights; change dark mode in Settings.

## Data integrity and limits

- SQLite stores teams, Pokémon child records, activity, and local coach decisions; it enables foreign-key enforcement and uses `ON DELETE CASCADE` when a team is removed. A legacy SQLite `preferences` table remains for schema upgrade compatibility but **the app now reads settings from SharedPreferences**.
- Saving a Pokémon checks the six-member limit and validates level/progress in both Dart and SQLite.
- Completed teams cannot be edited until reset; finishing is blocked until every member is at 100%.
- The coach is based on the **primary type chosen by the user** and entered training values. It is not a type-effectiveness engine, competitive ranking, or trained model.
- There is no cloud backup or sync. Uninstalling the app can remove the data. Test offline behavior before claiming it works on your platform.

## Assignment boundaries

The source includes app code, documentation, and tests but **does not supply or claim**: instructor proposal approval, group member sign-offs, authentic Git commit histories, a ClickUp project or four dated snapshots, real peer feedback, verified two-device testing, test execution output, a release APK, a 20–25-minute YouTube recording, or final submission receipts. These require action and evidence from the student/team. See `docs/ASSIGNMENT_AUDIT.md` and `docs/SUBMISSION_CHECKLIST.md`.

No deadline dates from the provided PDFs are assumed in this release.
