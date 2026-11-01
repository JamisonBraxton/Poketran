import '../data/models.dart';

/// Actions target an existing, explicit, human-confirmed screen or workflow.
enum CoachAction { addMember, editMember, finishTeam, none }

/// A rules-based offline suggestion, never a trained/remote AI prediction.
class CoachTip {
  final String key;
  final String headline;
  final String rationale;
  final String action;
  final int priority;
  final CoachAction actionType;
  final int? memberId;

  const CoachTip({
    required this.key,
    required this.headline,
    required this.rationale,
    required this.action,
    required this.priority,
    this.actionType = CoachAction.none,
    this.memberId,
  });
}

class TeamAdvisor {
  /// Simple comparison baseline: the least-trained saved member.
  static String baseline(List<PokeMember> roster) {
    if (roster.isEmpty) return 'Recruit your first Pokémon.';
    final sorted = [...roster]
      ..sort((a, b) => a.progress.compareTo(b.progress));
    return 'Train ${sorted.first.displayName} next (${sorted.first.progress}%).';
  }

  /// Scores candidate actions based only on user-entered, on-device records.
  static List<CoachTip> advise(List<PokeMember> roster) {
    if (roster.isEmpty) {
      return const [CoachTip(
        key: 'empty',
        headline: 'Build your starting lineup',
        rationale: 'No Pokémon have been added, so coverage and training cannot be measured.',
        action: 'Add a Pokémon and choose its primary type.',
        priority: 100,
        actionType: CoachAction.addMember,
      )];
    }
    final tips = <CoachTip>[];
    final counts = <PokeType, int>{};
    for (final p in roster) {
      counts[p.type] = (counts[p.type] ?? 0) + 1;
    }
    if (roster.length < 6) {
      tips.add(CoachTip(
        key: 'open-slots',
        headline: 'You have ${6 - roster.length} open roster slots',
        rationale: 'A full six-member roster gives you more tactical options.',
        action: 'Recruit ${6 - roster.length} more Pokémon with a new primary type.',
        priority: 40 + (6 - roster.length) * 3,
        actionType: CoachAction.addMember,
      ));
    }
    final duplicates = counts.entries.where((e) => e.value > 1).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (duplicates.isNotEmpty) {
      final repeated = duplicates.first;
      final matching = roster.firstWhere((p) => p.type == repeated.key);
      tips.add(CoachTip(
        key: 'type-${repeated.key.name}',
        headline: 'Diversify ${repeated.key.label} coverage',
        rationale: '${repeated.value} Pokémon share the ${repeated.key.label} primary type. '
            'Distinct types can offer more varied options; overlap is not always bad.',
        action: roster.length < 6
            ? 'Consider a different type when filling an open slot.'
            : 'Review ${matching.displayName} and consider whether its type belongs in this lineup.',
        priority: 65 + repeated.value,
        actionType: roster.length < 6 ? CoachAction.addMember : CoachAction.editMember,
        memberId: roster.length < 6 ? null : matching.id,
      ));
    }
    final lowProgress = roster.where((p) => p.progress < 50).toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));
    if (lowProgress.isNotEmpty) {
      final lowest = lowProgress.first;
      tips.add(CoachTip(
        key: 'train-${lowest.id ?? lowest.species}',
        headline: 'Focus on ${lowest.displayName}',
        rationale: '${lowest.displayName} is at ${lowest.progress}% training, '
            'the lowest among members below halfway.',
        action: 'Open ${lowest.displayName}, train, and save updated progress.',
        priority: 85 - lowest.progress ~/ 4,
        actionType: CoachAction.editMember,
        memberId: lowest.id,
      ));
    }
    final noRoles = roster.where((p) => p.role.trim().toLowerCase() == 'undecided').toList();
    if (noRoles.isNotEmpty) {
      final target = noRoles.first;
      tips.add(CoachTip(
        key: 'role-${target.id ?? target.species}',
        headline: 'Clarify a team role',
        rationale: '${noRoles.length} Pokémon have an undecided role.',
        action: 'Give ${target.displayName} a role, such as attacker or support.',
        priority: 55,
        actionType: CoachAction.editMember,
        memberId: target.id,
      ));
    }
    final ready = roster.where((p) => p.progress == 100).length;
    if (ready == roster.length) {
      tips.add(const CoachTip(
        key: 'all-ready',
        headline: 'Your roster is ready',
        rationale: 'Every saved Pokémon has reached 100% training progress.',
        action: 'If training has started, mark this team Completed.',
        priority: 99,
        actionType: CoachAction.finishTeam,
      ));
    } else if (lowProgress.isEmpty) {
      final target = roster.firstWhere((p) => p.progress < 100);
      tips.add(CoachTip(
        key: 'finish-${target.id ?? target.species}',
        headline: 'Close out the remaining training',
        rationale: '$ready of ${roster.length} Pokémon are at 100%.',
        action: 'Open ${target.displayName} and finish the remaining progress.',
        priority: 70,
        actionType: CoachAction.editMember,
        memberId: target.id,
      ));
    }
    tips.sort((a, b) => b.priority.compareTo(a.priority));
    return tips;
  }

  static bool identifiesTypeOverlap(List<PokeMember> roster) =>
      advise(roster).any((tip) => tip.key.startsWith('type-'));
}
