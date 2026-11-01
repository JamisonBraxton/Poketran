import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/database_service.dart';
import '../widgets/common_widgets.dart';

class SettingsPage extends StatefulWidget {
  final AppPreferences preferences;
  final Future<void> Function(AppPreferences next, String key, bool value)
      onPreferencesChanged;
  const SettingsPage({super.key, required this.preferences,
      required this.onPreferencesChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  Future<void> _demo() async {
    if (_busy) return;
    if (!await askConfirm(context,
        title: 'Add a demo team?',
        message: 'This adds a sample Kanto team with six Pokémon. It will not overwrite your existing teams.',
        action: 'Add demo team')) return;
    setState(() => _busy = true);
    try {
      await DatabaseService.instance.createDemoTeam();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo team created. Open the Teams tab to explore it.')));
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change(String key, bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final prefs = AppPreferences(
      darkMode: key == 'darkMode' ? value : widget.preferences.darkMode,
      showHints: key == 'showHints' ? value : widget.preferences.showHints,
    );
    try {
      await widget.onPreferencesChanged(prefs, key, value);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28), children: [
      const SectionLabel('Customize your journey',
          subtitle: 'These settings survive app restarts.'),
      Card(child: Column(children: [
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Dark mode'),
          subtitle: const Text('Switch between midnight and daylight colors.'),
          value: widget.preferences.darkMode,
          onChanged: _busy ? null : (v) => _change('darkMode', v),
        ),
        const Divider(height: 1),
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome_outlined),
          title: const Text('Show local coach'),
          subtitle: const Text('Display rules-based tips on the team screen.'),
          value: widget.preferences.showHints,
          onChanged: _busy ? null : (v) => _change('showHints', v),
        ),
      ])),
      const SectionLabel('Explore a working example'),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Populate a sample team for a quick tour.'),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _demo,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Create demo team'),
          ),
        ],
      ))),
      const SectionLabel('Offline by design'),
      const Card(child: Padding(padding: EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.offline_bolt, size: 22), SizedBox(width: 9),
            Expanded(child: Text('No account. No internet. No cloud backend.',
                style: TextStyle(fontWeight: FontWeight.w800)))]),
          SizedBox(height: 11),
          Text('Teams, Pokémon, and activity use on-device SQLite; display preferences '
              'use SharedPreferences. Uninstalling may erase the data. The app '
              'does not fetch copyrighted game images or Pokémon data.'),
        ],
      ))),
      const SectionLabel('About Pokétran'),
      const Card(child: Padding(padding: EdgeInsets.all(18), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pokétran • Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text('An unofficial student-made team planner. Not affiliated with, '
              'endorsed by, or sponsored by Nintendo, Game Freak, Creatures, '
              'or The Pokémon Company.'),
          SizedBox(height: 8),
          Text('Hand-entered records only; type guidance is a simple heuristic '
              'and does not model battle matchups.'),
        ],
      ))),
    ],
  );
}
