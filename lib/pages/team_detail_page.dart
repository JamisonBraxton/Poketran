import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/database_service.dart';
import '../data/models.dart';
import '../logic/team_advisor.dart';
import '../widgets/common_widgets.dart';
import 'pokemon_editor_page.dart';
import 'team_editor_page.dart';

class TeamDetailPage extends StatefulWidget {
  final int teamId;
  final bool showHints;
  const TeamDetailPage({super.key, required this.teamId, required this.showHints});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  TeamRecord? _team;
  List<PokeMember> _roster = [];
  Set<String> _dismissedTips = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final team = await DatabaseService.instance.getTeam(widget.teamId);
      final roster = await DatabaseService.instance.getMembers(widget.teamId);
      final dismissed = await DatabaseService.instance.getDismissedCoachTips(widget.teamId);
      if (mounted) setState(() {
        _team = team; _roster = roster; _dismissedTips = dismissed;
        _loading = false; _error = null;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _editTeam() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
        builder: (_) => TeamEditorPage(team: _team)));
    if (saved == true) await _load();
  }

  Future<void> _editMember([PokeMember? member]) async {
    if (_team?.status == TeamStatus.complete) {
      showAppError(context, const ValidationException(
          'Reset a completed team before editing its roster.'));
      return;
    }
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
        builder: (_) => PokemonEditorPage(teamId: widget.teamId, member: member)));
    if (saved == true) await _load();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success)));
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _coachNotNow(CoachTip tip) async {
    await _run(() => DatabaseService.instance.recordCoachChoice(
        widget.teamId, tip.key, 'not_now'), 'Suggestion hidden until the roster changes.');
  }

  Future<void> _coachApply(CoachTip tip) async {
    try {
      await DatabaseService.instance.recordCoachChoice(widget.teamId, tip.key, 'apply');
      if (!mounted) return;
      switch (tip.actionType) {
        case CoachAction.addMember:
          if (_team?.status == TeamStatus.complete || _roster.length >= 6) {
            showAppError(context, const ValidationException('No available team slot.'));
          } else {
            await _editMember();
          }
          break;
        case CoachAction.editMember:
          final targets = _roster.where((p) => p.id == tip.memberId).toList();
          if (targets.isNotEmpty) {
            await _editMember(targets.first);
          } else {
            showAppError(context, const ValidationException(
                'That Pokémon is unavailable. Edit your roster manually.'));
          }
          break;
        case CoachAction.finishTeam:
          if (_team?.status == TeamStatus.active) {
            await _run(() => DatabaseService.instance.changeStatus(
                widget.teamId, TeamStatus.complete), 'Team completed!');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Start training first, or reset a completed team.')));
          }
          break;
        case CoachAction.none:
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Suggestion saved for review.')));
          break;
      }
      if (mounted) await _load();
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _revealTips() async {
    await _run(() => DatabaseService.instance.revealCoachTips(widget.teamId),
      'Hidden suggestions restored.');
  }

  Future<void> _deleteTeam() async {
    if (!await askConfirm(context, title: 'Delete this team?',
        message: 'All roster entries for this team will be permanently deleted. '
            'The activity timeline will retain the deletion event.', action: 'Delete team')) return;
    try {
      await DatabaseService.instance.deleteTeam(widget.teamId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _removeMember(PokeMember member) async {
    if (_team?.status == TeamStatus.complete) {
      showAppError(context, const ValidationException(
          'Reset a completed team before releasing Pokémon.'));
      return;
    }
    if (!await askConfirm(context, title: 'Release ${member.displayName}?',
        message: 'Remove this Pokémon from the team? This cannot be undone.',
        action: 'Release')) return;
    await _run(() => DatabaseService.instance.deleteMember(member),
        '${member.displayName} removed.');
  }

  Future<void> _reset() async {
    if (!await askConfirm(context, title: 'Reset training progress?',
        message: 'All Pokémon progress will return to 0%. The Pokémon themselves '
            'will remain on the team.', action: 'Reset team')) return;
    await _run(() => DatabaseService.instance.resetTeam(widget.teamId), 'Team reset.');
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    return Scaffold(
      appBar: AppBar(title: Text(team?.name ?? 'Team details'), actions: [
        if (team != null) PopupMenuButton<String>(
          tooltip: 'Team actions',
          onSelected: (value) {
            if (value == 'edit') _editTeam();
            if (value == 'reset') _reset();
            if (value == 'delete') _deleteTeam();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit team details')),
            PopupMenuItem(value: 'reset', child: Text('Reset training')),
            PopupMenuItem(value: 'delete', child: Text('Delete team')),
          ],
        ),
      ]),
      floatingActionButton: team != null && team.status != TeamStatus.complete && _roster.length < 6
          ? FloatingActionButton.extended(
              onPressed: () => _editMember(),
              backgroundColor: brandYellow,
              foregroundColor: const Color(0xFF141725),
              icon: const Icon(Icons.add), label: const Text('Add Pokémon'),
            )
          : null,
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? EmptyState(title: 'Unable to open team',
                message: _error!, buttonLabel: 'Retry', onPressed: _load)
          : team == null ? const EmptyState(title: 'Team not found',
                message: 'The team may have been deleted.')
          : _body(team),
    );
  }

  Widget _body(TeamRecord team) {
    final average = _roster.isEmpty ? 0.0 :
      _roster.map((p) => p.progress).reduce((a, b) => a + b) / _roster.length;
    final ready = _roster.where((p) => p.progress == 100).length;
    final tips = TeamAdvisor.advise(_roster)
        .where((tip) => !_dismissedTips.contains(tip.key)).toList();
    return RefreshIndicator(onRefresh: _load, child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 120), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const PokeballMark(size: 50), const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900)),
                  Text('${team.region} • Updated ${shortDate(team.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ])),
              StatusPill(status: team.status),
            ]),
            const SizedBox(height: 15),
            Text(team.goal),
            const SizedBox(height: 19),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Average training', style: Theme.of(context).textTheme.labelLarge),
              Text('${average.round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 7),
            LinearProgressIndicator(value: average / 100, minHeight: 10,
                borderRadius: BorderRadius.circular(12)),
            const SizedBox(height: 10),
            Text('${_roster.length}/6 Pokémon • $ready ready',
              style: Theme.of(context).textTheme.bodySmall),
          ],
        ))),
        const SizedBox(height: 10),
        _workflow(team),
        const SectionLabel('Roster', subtitle: 'Tap a Pokémon to edit its training and strategy.'),
        if (_roster.isEmpty)
          EmptyState(title: 'Your roster is empty',
            message: 'Add up to six Pokémon to start building this team.',
            buttonLabel: 'Add Pokémon', onPressed: () => _editMember())
        else
          ..._roster.map((member) => Card(child: InkWell(
            onTap: () => _editMember(member),
            borderRadius: BorderRadius.circular(22),
            child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [
              Row(children: [
                Container(width: 45, height: 45, alignment: Alignment.center,
                  decoration: BoxDecoration(color: typeColor(member.type).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14)),
                  child: Text(typeEmoji(member.type), style: const TextStyle(fontSize: 25))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${member.species} • Lv ${member.level} • ${member.role}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                  ])),
                PopupMenuButton<String>(
                  tooltip: 'Pokémon actions',
                  onSelected: (choice) {
                    if (choice == 'edit') _editMember(member);
                    if (choice == 'delete') _removeMember(member);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit Pokémon')),
                    PopupMenuItem(value: 'delete', child: Text('Release Pokémon')),
                  ],
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [TypePill(type: member.type), const Spacer(),
                Text('${member.progress}% trained',
                    style: Theme.of(context).textTheme.bodySmall)]),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: member.progress / 100,
                  minHeight: 6, borderRadius: BorderRadius.circular(8)),
              if (member.notes.isNotEmpty) ...[
                const SizedBox(height: 9),
                Align(alignment: Alignment.centerLeft, child: Text(member.notes,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall)),
              ],
            ])),
          ))),
        if (widget.showHints) ...[
          const SectionLabel('Offline team coach',
              subtitle: 'Rule-based suggestions, compared with a simple baseline. You decide.'),
          Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BASELINE: ${TeamAdvisor.baseline(_roster)}',
                style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              if (tips.isEmpty)
                const Text('No new suggestions. Reveal hidden tips or change your roster.'),
              if (tips.isNotEmpty) ...[
                Row(children: [const Icon(Icons.auto_awesome, color: brandYellow),
                  const SizedBox(width: 9),
                  Expanded(child: Text(tips.first.headline,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)))]),
                const SizedBox(height: 9),
                Text(tips.first.rationale),
                const SizedBox(height: 9),
                Text('SUGGESTED: ${tips.first.action}',
                  style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 14),
                Wrap(spacing: 10, children: [
                  FilledButton.icon(onPressed: () => _coachApply(tips.first),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Apply')),
                  OutlinedButton(onPressed: () => _coachNotNow(tips.first),
                    child: const Text('Not now')),
                ]),
                if (tips.length > 1) ...[
                  const Divider(height: 24),
                  Text('Other ideas', style: Theme.of(context).textTheme.labelLarge),
                  ...tips.skip(1).take(2).map((tip) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('• ${tip.headline}: ${tip.action}'),
                  )),
                ],
              ],
              if (_dismissedTips.isNotEmpty) ...[
                const SizedBox(height: 10),
                TextButton.icon(onPressed: _revealTips,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text('Reveal ${_dismissedTips.length} hidden tip(s)')),
              ],
              const Divider(height: 18),
              Text('Advice uses only your saved roster. Applying opens a normal edit '
                'screen; it does not secretly change Pokémon data.',
                style: Theme.of(context).textTheme.bodySmall),
            ]))),
        ],
      ],
    ));
  }

  Widget _workflow(TeamRecord team) => Card(child: Padding(
    padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TEAM JOURNEY', style: TextStyle(
            color: brandYellow, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(switch (team.status) {
              TeamStatus.planned => 'Plan your roster, then begin training.',
              TeamStatus.active => 'Keep training each Pokémon to 100%.',
              TeamStatus.complete => 'Team completed! You can reset and try again.',
            }, key: ValueKey(team.status)),
          )),
          const SizedBox(width: 10),
          if (team.status == TeamStatus.planned)
            FilledButton(onPressed: () => _run(
                () => DatabaseService.instance.changeStatus(team.id!, TeamStatus.active),
                'Training started.'), child: const Text('Start'))
          else if (team.status == TeamStatus.active)
            FilledButton(onPressed: () => _run(
                () => DatabaseService.instance.changeStatus(team.id!, TeamStatus.complete),
                'Team completed!'), child: const Text('Finish'))
          else
            OutlinedButton(onPressed: _reset, child: const Text('Reset')),
        ]),
      ],
    ),
  ));
}
