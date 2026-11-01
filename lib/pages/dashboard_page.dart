import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/database_service.dart';
import '../data/models.dart';
import '../widgets/common_widgets.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onCreate;
  final void Function(int id) onOpenTeam;
  const DashboardPage({super.key, required this.onCreate, required this.onOpenTeam});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<TeamRecord> _teams = [];
  List<PokeMember> _members = [];
  TeamStatus? _filter;
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final teams = await DatabaseService.instance.getTeams();
      final members = await DatabaseService.instance.getAllMembers();
      if (mounted) setState(() {
        _teams = teams; _members = members; _loading = false; _error = null;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(title: 'Could not load teams',
        message: _error!, buttonLabel: 'Retry', onPressed: _load);
    final shown = _teams.where((team) =>
        (_filter == null || team.status == _filter) &&
        ('${team.name} ${team.region} ${team.goal}'.toLowerCase()
            .contains(_query.toLowerCase()))).toList();
    final finished = _teams.where((t) => t.status == TeamStatus.complete).length;
    final training = _teams.where((t) => t.status == TeamStatus.active).length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 120), children: [
        _HeroCard(teamCount: _teams.length, onCreate: widget.onCreate),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _MetricCard(value: '${_teams.length}', label: 'TEAMS',
              icon: Icons.shield_outlined)),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(value: '${_members.length}', label: 'POKÉMON',
              icon: Icons.catching_pokemon)),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(value: '$finished', label: 'FINISHED',
              icon: Icons.emoji_events_outlined)),
        ]),
        const SizedBox(height: 6),
        SectionLabel('Your collection',
            subtitle: '$training teams currently training. Search or filter below.'),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
              hintText: 'Search teams, regions, or goals'),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
              label: const Text('All teams'), selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null))),
            ...TeamStatus.values.map((status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(status.label),
                selected: _filter == status,
                onSelected: (_) => setState(() => _filter = status)),
            )),
          ]),
        ),
        const SizedBox(height: 10),
        if (_teams.isEmpty)
          EmptyState(title: 'Every journey starts with a team',
            message: 'Create your first Pokémon lineup. No sign-in or internet needed.',
            buttonLabel: 'Create my team', onPressed: widget.onCreate)
        else if (shown.isEmpty)
          const EmptyState(title: 'No matching teams',
              message: 'Try another search or status filter.')
        else
          ...shown.map((team) {
            final roster = _members.where((p) => p.teamId == team.id).toList();
            final progress = roster.isEmpty ? 0.0 :
                roster.map((p) => p.progress).reduce((a, b) => a + b) /
                    roster.length / 100;
            return Card(child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => widget.onOpenTeam(team.id!),
              child: Padding(padding: const EdgeInsets.all(17), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const PokeballMark(size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800)),
                      Text(team.region, style: Theme.of(context).textTheme.bodySmall),
                    ])),
                  StatusPill(status: team.status),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right),
                ]),
                const SizedBox(height: 12),
                Text(team.goal, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 15),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${roster.length}/6 roster slots',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text('${(progress * 100).round()}% trained',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress, minHeight: 7,
                  borderRadius: BorderRadius.circular(12)),
                if (roster.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 5, runSpacing: 5, children: roster.map((p) =>
                      TypePill(type: p.type)).toList()),
                ],
              ])),
            ));
          }),
      ]),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int teamCount;
  final VoidCallback onCreate;
  const _HeroCard({required this.teamCount, required this.onCreate});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF343E8D), Color(0xFF543B88)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('YOUR TRAINER JOURNEY',
          style: TextStyle(color: brandYellow, letterSpacing: 1.2,
              fontSize: 11, fontWeight: FontWeight.w900))),
        const PokeballMark(size: 47),
      ]),
      const SizedBox(height: 3),
      Text(teamCount == 0 ? 'Dream team.\nYour rules.' : 'Keep building.\nKeep growing.',
        style: const TextStyle(color: Colors.white, height: 1.15,
            fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 11),
      const Text('Plan a lineup, log training and become a better strategist.',
          style: TextStyle(color: Color(0xFFE3E3FF))),
      const SizedBox(height: 17),
      OutlinedButton.icon(onPressed: onCreate,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFBCC0FF))),
        icon: const Icon(Icons.add), label: const Text('Create a team')),
    ]),
  );
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _MetricCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    child: Column(children: [
      Icon(icon, size: 20, color: brandBlue),
      const SizedBox(height: 6),
      Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900)),
      const SizedBox(height: 3),
      FittedBox(child: Text(label, style: Theme.of(context).textTheme.labelSmall)),
    ]),
  ));
}
