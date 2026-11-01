import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme.dart';
import 'data/database_service.dart';
import 'data/settings_store.dart';
import 'data/models.dart';
import 'pages/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const PoketranApp());
}

class PoketranApp extends StatefulWidget {
  const PoketranApp({super.key});

  @override
  State<PoketranApp> createState() => _PoketranAppState();
}

class _PoketranAppState extends State<PoketranApp> {
  final _settings = const SettingsStore();
  AppPreferences _prefs = const AppPreferences();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Force database initialization as well, so errors are visible at startup.
      await DatabaseService.instance.database;
      final prefs = await _settings.read();
      if (!mounted) return;
      setState(() { _prefs = prefs; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _updatePrefs(AppPreferences next, String key, bool value) async {
    await _settings.save(key, value);
    if (mounted) setState(() => _prefs = next);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pokétran',
    debugShowCheckedModeBanner: false,
    theme: appTheme(false),
    darkTheme: appTheme(true),
    themeMode: _prefs.darkMode ? ThemeMode.dark : ThemeMode.light,
    home: _loading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _error != null
            ? Scaffold(body: EmptyDbError(message: _error!, onRetry: () {
                setState(() { _loading = true; _error = null; });
                _load();
              }))
            : HomeShell(preferences: _prefs, onPreferencesChanged: _updatePrefs),
  );
}

class EmptyDbError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const EmptyDbError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48),
      const SizedBox(height: 12),
      const Text('Could not open local data.'),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  ));
}
