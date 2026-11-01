import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/database_service.dart';
import '../data/models.dart';
import '../widgets/common_widgets.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});
  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  List<TeamRecord> _teams = [];
  List<PokeMember> _members = [];
  List<ActivityEntry> _activity = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final teams = await DatabaseService.instance.getTeams();
      final members = await DatabaseService.instance.getAllMembers();
      final activity = await DatabaseService.instance.getActivity();
      if (mounted) setState(() {
        _teams = teams; _members = members; _activity = activity;
        _loading = false; _error = null;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(title: 'Could not load insights',
        message: _error!, buttonLabel: 'Retry', onPressed: _load);
    final totalProgress = _members.isEmpty ? 0.0 :
        _members.map((m) => m.progress).reduce((a, b) => a + b) / _members.length;
    final ready = _members.where((p) => p.progress == 100).length;
    final complete = _teams.where((t) => t.status == TeamStatus.complete).toList();
    final counts = <PokeType, int>{};
    for (final p in _members) { counts[p.type] = (counts[p.type] ?? 0) + 1; }
    final typeCounts = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return RefreshIndicator(onRefresh: _load, child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 45), children: [
        const SectionLabel('Trainer overview',
            subtitle: 'All numbers are calculated from saved local records.'),
        Row(children: [
          Expanded(child: _InsightMetric('${totalProgress.round()}%', 'Average training')),
          const SizedBox(width: 10),
          Expanded(child: _InsightMetric('$ready', 'Fully trained')),
          const SizedBox(width: 10),
          Expanded(child: _InsightMetric('${complete.length}', 'Completed teams')),
        ]),
        const SectionLabel('Primary-type mix',
            subtitle: 'How your collected Pokémon are distributed by type.'),
        if (typeCounts.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(22),
              child: Text('Add Pokémon to see your type distribution.')))
        else
          Card(child: Padding(padding: const EdgeInsets.all(18),
            child: Column(children: typeCounts.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                SizedBox(width: 100, child: TypePill(type: entry.key)),
                const SizedBox(width: 12),
                Expanded(child: LinearProgressIndicator(
                  value: entry.value / _members.length,
                  minHeight: 9, borderRadius: BorderRadius.circular(10),
                  color: typeColor(entry.key))),
                const SizedBox(width: 12),
                Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            )).toList()),
          )),
        const SectionLabel('Completed journeys',
            subtitle: 'Finished teams remain in your collection until deleted or reset.'),
        if (complete.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(22),
            child: Text('No completed teams yet. Train every Pokémon to 100%, then finish your team.')))
        else
          ...complete.map((team) => Card(child: ListTile(
            leading: const Icon(Icons.emoji_events, color: brandYellow),
            title: Text(team.name), subtitle: Text(team.goal, maxLines: 1,
                overflow: TextOverflow.ellipsis),
            trailing: Text(shortDate(team.updatedAt)),
          ))),
        const SectionLabel('Activity history',
            subtitle: 'A dated, device-local record of your actions.'),
        if (_activity.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(22),
            child: Text('Your activity history will appear here after your first save.')))
        else
          Card(child: Column(children: [
            ..._activity.map((event) => Column(children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.bolt, size: 18)),
                title: Text(event.title),
                subtitle: Text(event.detail),
                trailing: Text(shortDate(event.createdAt),
                    style: Theme.of(context).textTheme.labelSmall),
              ),
              if (event.id != _activity.last.id) const Divider(height: 1),
            ])),
          ])),
      ],
    ));
  }
}

class _InsightMetric extends StatelessWidget {
  final String number;
  final String label;
  const _InsightMetric(this.number, this.label);

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 18),
    child: Column(children: [
      Text(number, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900, color: brandYellow)),
      const SizedBox(height: 5),
      Text(label, style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center),
    ]),
  ));
}
