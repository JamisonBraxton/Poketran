# Pokétran technical architecture

## Use case and user stories

Intended users are student trainers or fans who want a private, offline lineup and training journal.

1. As a user managing multiple lineups, I want to create and rename teams so I can plan different goals.
2. As a trainer, I want to update a member's training progress so I can see readiness accurately.
3. As a fan, I want transparent, optional recommendations with reasons so I can decide whether to change the roster.

## Screen roles and state

| Role | Dart widgets | Typical action |
|---|---|---|
| Catalog/dashboard | `DashboardPage` | Search/filter teams, browse progress |
| Create/edit | `TeamEditorPage`, `PokemonEditorPage` | Validated form, dropdown, slider and save |
| Detail/activity | `TeamDetailPage` | Two-entity CRUD, workflow, coaching decisions |
| History/insights | `InsightsPage` | Aggregates, type counts and dated activity |
| Settings | `SettingsPage` | Persisted theme and coach toggle, seed local demo |

`HomeShell` uses a `NavigationBar` on narrow screens and `NavigationRail` at widths >=720 logical pixels. Screens with data loading, controls, and forms are `StatefulWidget`s. Labels, type/status pills, dialogs, and decorative symbols are reusable `StatelessWidget`s. Async persistence errors are shown to the user. Controllers are disposed in editors; no network calls are made.

## Local storage schema

```text
teams
  id INTEGER PRIMARY KEY AUTOINCREMENT
  name TEXT NOT NULL
  goal TEXT NOT NULL
  region TEXT NOT NULL
  status TEXT CHECK planned | active | complete
  created_at, updated_at INTEGER
      1 ──────── *
pokemon
  id INTEGER PRIMARY KEY AUTOINCREMENT
  team_id INTEGER NOT NULL REFERENCES teams(id) ON DELETE CASCADE
  species, nickname, type, role, notes TEXT
  level INTEGER CHECK 1..100
  progress INTEGER CHECK 0..100
  created_at, updated_at INTEGER

activity
  id INTEGER PRIMARY KEY AUTOINCREMENT
  title, detail TEXT; created_at INTEGER

coach_feedback
  (team_id, tip_key) PRIMARY KEY
  team_id REFERENCES teams(id) ON DELETE CASCADE
  decision TEXT CHECK apply | not_now
  updated_at INTEGER

preferences  [legacy SQLite table only; no current reads]
  key TEXT PRIMARY KEY; value TEXT

SharedPreferences
  poketran.darkMode: bool (defaults true)
  poketran.showHints: bool (defaults true)
```

The required *two related CRUD entities* are `teams` and `pokemon`. Activity/feedback are supporting tables. Data changes use transactions. Every deletion of a team removes its Pokémon and feedback; the independent event history remains. Schema version 2 creates coach feedback and upgrades a version-1 local SQLite database without deleting teams and Pokémon. Database filename is `poketran.db`. Renaming an **already installed** PokéPilot app does not automatically import its existing Android app data, because app IDs differ.

## State transitions

```text
Planned  ── Start (at least one member) ──> Training
Training ── Finish (all members 100%) ──> Completed
Any state ── Reset (confirmed) ──> Planned, all progress zeroed
```

Completed members cannot be edited or deleted without reset. Edits invalidate stored `Not now` tip suppression; the helper recomputes from the updated SQLite roster. Theme and coach visibility are lightweight device settings in SharedPreferences.

## Local helper

`TeamAdvisor` takes a local list of `PokeMember` and returns ranked `CoachTip`s with `key`, priority, rationale, suggested next step, and `CoachAction`. The comparison baseline only picks lowest progress; the enhanced coach also recognizes repeated primary types, open slots, uncertain roles, and readiness. **Apply** routes to the editor or finish workflow; it does not silently write roster data. **Not now** persists a decision, and **Reveal** clears dismissals. No remote requests or machine-learning model.

## Why this design

- Keeps storage code out of widgets and deterministic advice out of persistence.
- Uses local SQL transactions and strong constraints for a small offline dataset.
- Offers explicit user control and avoids overstating rule-based suggestions as learned AI.
- Allows a clear VS Code demonstration of UI -> validation -> database -> back to UI.

## Limitations

No licensed Pokémon images, game-stat ingestion, dual-type validation, battle effectiveness, account creation, notifications, or cloud sync. Landscape behavior and accessibility need real device verification. No production build or execution results are provided with the source ZIP.
