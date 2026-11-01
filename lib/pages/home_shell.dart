import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_page.dart';
import 'insights_page.dart';
import 'settings_page.dart';
import 'team_detail_page.dart';
import 'team_editor_page.dart';

class HomeShell extends StatefulWidget {
  final AppPreferences preferences;
  final Future<void> Function(AppPreferences next, String key, bool value)
      onPreferencesChanged;
  const HomeShell({super.key, required this.preferences,
      required this.onPreferencesChanged});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  int _refresh = 0;

  void _selectTab(int index) => setState(() {
    _tab = index;
    _refresh++;
  });

  Future<void> _createTeam() async {
    final saved = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const TeamEditorPage()));
    if (saved == true && mounted) setState(() => _refresh++);
  }

  Future<void> _openTeam(int id) async {
    await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => TeamDetailPage(teamId: id,
            showHints: widget.preferences.showHints)));
    if (mounted) setState(() => _refresh++);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Android phone portrait -> bottom navigation. Tablet or landscape -> rail.
      final wide = constraints.maxWidth >= 720;
      const destinations = [
        NavigationDestination(icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield), label: 'Teams'),
        NavigationDestination(icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights), label: 'Insights'),
        NavigationDestination(icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune), label: 'Settings'),
      ];
      final titles = ['My teams', 'Insights & history', 'Settings'];
      return Scaffold(
        appBar: AppBar(
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            const PokeballMark(size: 29),
            const SizedBox(width: 12),
            Text(titles[_tab], style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          actions: [
            if (_tab == 0) IconButton(onPressed: _createTeam,
                tooltip: 'Create team', icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
        body: Row(children: [
          if (wide) NavigationRail(
            selectedIndex: _tab,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: _selectTab,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield), label: Text('Teams')),
              NavigationRailDestination(icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights), label: Text('Insights')),
              NavigationRailDestination(icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune), label: Text('Settings')),
            ],
          ),
          if (wide) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: Align(alignment: Alignment.topCenter,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 980),
              child: IndexedStack(index: _tab, children: [
                DashboardPage(key: ValueKey('dashboard$_refresh'),
                    onCreate: _createTeam, onOpenTeam: _openTeam),
                InsightsPage(key: ValueKey('insights$_refresh')),
                SettingsPage(preferences: widget.preferences,
                    onPreferencesChanged: widget.onPreferencesChanged),
              ])))),
        ]),
        floatingActionButton: _tab == 0 ? FloatingActionButton.extended(
          onPressed: _createTeam,
          backgroundColor: brandYellow,
          foregroundColor: const Color(0xFF141725),
          icon: const Icon(Icons.add),
          label: const Text('New team'),
        ) : null,
        bottomNavigationBar: wide ? null : NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _selectTab,
          destinations: destinations,
        ),
      );
    },
  );
}
