# Pokétran — audit against the expanded Project 1 implementation guide

**Basis:** User-provided 36-page "Build Guide / Project One Flutter Studio" PDF and earlier 7-page project summary. All dates intentionally omitted as requested. **Audit labels:** SOURCE = implemented in source, UNVERIFIED = requires Flutter/tool/device execution, MISSING = requires genuine student/team process or artifact, OPTIONAL = bonus/graduate-only unless applicable. Do not treat a source item as proof of a passed test.

| Guide pages | Requirement | Status | Evidence / next action |
|---|---|---|---|
| 1–4 | Instructor approval before implementation | MISSING | Get actual instructor/team approval; do not fabricate approval |
| 1–4, 24–29 | Fresh shared GitHub repo, feature branches, PRs, 20+ meaningful commits **per member** | MISSING | Create repo and perform attributable future work; imported source does not create legitimate past history |
| 3–4, 17–20 | ClickUp board, ownership, acceptance criteria, actual task-to-commit/test links, four dated evidence snapshots | MISSING | Maintain actual board through remaining development; produce PDF evidence |
| 6, 10 | Five distinct roles | SOURCE, UNVERIFIED | Dashboard, team/member editors, detail/activity, insights/history, settings; navigate all |
| 6, 23 | Responsive portrait/landscape | SOURCE, UNVERIFIED | NavigationBar <720px, NavigationRail >=720px; test both orientations and UI overflow |
| 6–7, 9 | Forms, stateful/stateless widgets, navigation, list, gestures, dialogs, buttons | SOURCE | Editors, `HomeShell`, common widgets, confirmation prompts |
| 9 | Meaningful numeric slider | SOURCE | `PokemonEditorPage` progress percentage 0–100 |
| 6–7, 9–10 | Two related entities, CRUD both, validation, parent-delete rule, foreign key | SOURCE, UNVERIFIED | `teams` + `pokemon`, transactions, cascades, database tests |
| 6, 10 | `SharedPreferences` for settings | SOURCE, UNVERIFIED | `SettingsStore`, dark/coach toggles, tests; old SQLite table unused |
| 10 | Start/progress/finish/reset and persisted activity | SOURCE, UNVERIFIED | Team status + child progress, activity history |
| 10 | Search, filter, one aggregate | SOURCE | Search by name/goal/region, status filter, training averages and type counts |
| 7 | Theming, animations, accessibility | SOURCE PARTIAL, UNVERIFIED | Material 3, color theme, workflow AnimatedSwitcher, labels; accessibility audit still required |
| 10–11, 17 | Fully offline; no cloud app dependencies | SOURCE, UNVERIFIED | No app network APIs, all team data local; test in airplane mode |
| 13–16 | A local, explainable helper and simple baseline | SOURCE, UNVERIFIED | `TeamAdvisor` and `AI_FEATURE.md` |
| 13–16 | Explicit control and five-case evaluation | SOURCE, UNVERIFIED | Apply/Not now/Reveal and five named synthetic cases; run tests, report actual results |
| 8, 16 | Graduate extras: architecture, two methods, more tests/coverage, background/local notifications | OPTIONAL / NOT IMPLEMENTED | Undergrad core only; don't claim grad compliance |
| 12 | Bonus: export, charts, biometrics, camera | OPTIONAL / NOT IMPLEMENTED | Dark mode is included; no extra-credit claims made |
| 7, 22, 32 | README, project overview, user guide, technology, architecture | SOURCE | Root README, ARCHITECTURE, AI_FEATURE |
| 3–4, 34–35 | Tests on **two** devices/emulators, restart, offline, peer revision | MISSING | Run `docs/TEST_PLAN.md` and `docs/PEER_TEST_TEMPLATE.md`; retain evidence |
| 30–33 | Android **release APK** installed and launched | MISSING | Run `flutter build apk --release`, install and record real evidence |
| 29–33 | Word proposal, signed statement, report, slide deck, Q&A Word selection | MISSING | Create real student documents, get necessary signatures/approval |
| 29–33 | 20–25-minute team video with YouTube link, in-app demo, code trace and questions | MISSING | Use `docs/SHOWCASE_OUTLINE.md`; each member participates |
| 19–20, 31–33 | `Kanban_Contribution_Evidence.pdf` with four snapshots and actual traced task | MISSING | Produce from real ClickUp activity, include in repo and final ZIP |
| 31–33 | `AI_FEATURE.md` and development AI usage log | SOURCE, UNVERIFIED | Read and verify the documents match the actual app and test results |
| 30–33 | Each group member submits an individual complete ZIP to iCollege | MISSING | Package all required artifacts and verify individual upload receipts |

## Implementation changes made in this revision

- Renamed app identity from PokéPilot to **Pokétran**, package/project identifier to `poketran`.
- Added Windows bootstrap native-label adjustment for Android launcher and Windows title.
- Moved light settings to real `shared_preferences` with dedicated tests.
- Added SQLite v2 `coach_feedback` persistence with schema upgrade path.
- Added Apply / Not now / Reveal controls and explicit coach action destinations.
- Added five labeled evaluation cases plus feedback persistence and six-member tests.
- Added wide-screen navigation rail and a short workflow transition animation.
- Updated truthful submission, architecture, smart-helper, peer evaluation and testing documentation.

## Source limitations discovered

- This artifact contains **Flutter/Dart source and test files**, not generated native runner folders and not an APK. `flutter create` on the developer's Flutter SDK supplies native boilerplate; do not submit before `flutter analyze`/`flutter test`/release-build checks have succeeded locally.
- The coach uses user-selected *primary* type, not official game mechanics. It may suggest diversification even when two members of the same type are a good strategic choice.
- The existing SQLite database filename was changed to `poketran.db` for the renamed app. Android installations with different app identifiers cannot share databases automatically.
- The PDF references separate topic briefs and rubrics not present in the two files; check those course resources for any more detailed requirements and use your instructor's official approval process.

**Audit outcome:** The basic undergraduate app features have code coverage in this source; the release, human process, and verification gates remain open. This is **not** a ready-to-submit completed assignment package.
