# Source static checks performed during preparation

The assistant inspected the revised directory, searched for obsolete Dart package imports, parsed `pubspec.yaml`, ran a basic bracket/quote balance check across Dart files, and copied the SQLite `CREATE TABLE`/`CREATE INDEX` statements into an isolated Python SQLite database to check their SQL syntax, foreign-key cascading behavior, and numeric CHECK constraints.

**Observed results:** YAML parsed, Dart delimiters balanced, SQLite schema created, team deletion removed its Pokémon and local coach feedback, and an out-of-range member level was rejected by SQLite.

**This is not a substitute for:** `dart format`, `flutter analyze`, `flutter test`, any Android or Windows build, real device testing, release-install testing, or peer acceptance. Those tasks were **not run** because the Flutter SDK is unavailable in this environment. Results still need to be collected locally.
