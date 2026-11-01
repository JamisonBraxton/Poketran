# Pokétran test plan — fill with observed results

**Current status: NOT EXECUTED in the source-generation environment (Flutter SDK unavailable).** Do not attach invented success screenshots or claim the app passed tests before running them.

## Automated checks

Run from project root, after `flutter create` and `flutter pub get`:

```powershell
flutter --version
flutter doctor
flutter analyze
flutter test
flutter test test/team_advisor_test.dart --reporter expanded
flutter test test/database_test.dart --reporter expanded
flutter test test/settings_store_test.dart --reporter expanded
```

Capture terminal output with actual dates, Flutter version, test count, and any failures. Make fixes and rerun until clean. Existing test files:

- `test/validation_test.dart`: name/goal/level/progress validation.
- `test/database_test.dart`: both entities CRUD, cascading parent deletion, lifecycle guards, six-member cap, coach dismissal persistence, sample/activity behavior.
- `test/team_advisor_test.dart`: five independent synthetic cases plus role and full-party constraints.
- `test/settings_store_test.dart`: SharedPreferences defaults/persistence/key validation.
- `test/widget_test.dart`: status/type display and cancelable delete dialog.

## Manual device / emulator matrix

Complete the table from **actual** work; show at least two different devices/emulators (for example, two Android virtual devices with different sizes). Save screenshots and device/emulator model names.

| Check | Procedure | Device A result | Device B result |
|---|---|---|---|
| Startup / offline | Turn off network, launch fresh app | NOT RUN | NOT RUN |
| Team CRUD | Create, open, edit, delete a team | NOT RUN | NOT RUN |
| Child CRUD | Add, open, edit, release a Pokémon | NOT RUN | NOT RUN |
| Parent deletion | Delete team with children, verify no orphan members | NOT RUN | NOT RUN |
| Validation | Invalid level 101, blank name, seventh member | NOT RUN | NOT RUN |
| Lifecycle | Start, set all members 100%, finish, reset | NOT RUN | NOT RUN |
| Restore | Close app process, reopen, confirm teams/history remain | NOT RUN | NOT RUN |
| Preferences | Change theme/coach toggle, force quit, reopen | NOT RUN | NOT RUN |
| Smart helper | Baseline, Apply, Not now, force close, Reveal, edited data | NOT RUN | NOT RUN |
| Layout | Portrait and landscape, overflow, reachable buttons | NOT RUN | NOT RUN |
| Accessibility | Screen-reader labels, text scaling, contrast and tap targets | NOT RUN | NOT RUN |
| Error feedback | Try invalid, blocked, and empty states | NOT RUN | NOT RUN |

## Peer-based usability revision (required)

1. Have a **real peer** try: create a team, add a member, change progress, locate the coach, finish training and find the activity record. Give no hints beyond the task script.
2. Record one specific observation, the confusing screen, a proposed correction and a screenshot/wireframe **before** the change.
3. Implement a real interface revision, commit the change with a meaningful message and link it to the ClickUp card.
4. Retest with a peer, record the observed result and capture the **after** screenshot/wireframe. Use `docs/PEER_TEST_TEMPLATE.md`.

## Release APK verification

Run:

```powershell
flutter build apk --release
flutter install
```

Or install the exact APK at `build/app/outputs/flutter-apk/app-release.apk` onto a connected Android emulator/device. Verify launch, offline CRUD, lifecycle, restart and stored preferences with the **release build**. Collect actual command outputs and APK file size.

## Smart-helper evaluation

The five inputs and expected outcomes are documented in `AI_FEATURE.md`. Report case-by-case observed values and error/limitation notes after executing the tests. Add a sixth manual edge case with an impossible level, confirm the editor rejects it, and note the outcome. Do not report accuracy percentages based on invented data.
