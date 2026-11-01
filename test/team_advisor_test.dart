import 'package:flutter_test/flutter_test.dart';
import 'package:poketran/data/models.dart';
import 'package:poketran/logic/team_advisor.dart';

PokeMember member(String species, PokeType type, int progress,
        {String role = 'Attacker', int? id}) =>
    PokeMember(id: id, teamId: 1, species: species, nickname: '', type: type,
      role: role, level: 30, progress: progress, notes: '');

void main() {
  // Five named, synthetic evaluation cases plus action/ranking assertions.
  test('CASE 1 empty roster: no-data behavior', () {
    expect(TeamAdvisor.advise([]).single.actionType, CoachAction.addMember);
    expect(TeamAdvisor.baseline([]), 'Recruit your first Pokémon.');
  });

  test('CASE 2 normal roster: training priority', () {
    final roster = [
      member('Pikachu', PokeType.electric, 80, id: 1),
      member('Eevee', PokeType.normal, 15, id: 2),
    ];
    expect(TeamAdvisor.baseline(roster), contains('Eevee'));
    expect(TeamAdvisor.advise(roster).first.headline, contains('Eevee'));
    expect(TeamAdvisor.advise(roster).first.memberId, 2);
  });

  test('CASE 3 overlap: helper detects what baseline misses', () {
    final roster = [
      member('Charmander', PokeType.fire, 30),
      member('Vulpix', PokeType.fire, 50),
    ];
    expect(TeamAdvisor.identifiesTypeOverlap(roster), isTrue);
    expect(TeamAdvisor.advise(roster).any((t) => t.key == 'type-fire'), isTrue);
    expect(TeamAdvisor.baseline(roster), isNot(contains('coverage')));
  });

  test('CASE 4 complete progress: suggest finishing', () {
    final roster = [member('Squirtle', PokeType.water, 100)];
    final best = TeamAdvisor.advise(roster).first;
    expect(best.headline, 'Your roster is ready');
    expect(best.actionType, CoachAction.finishTeam);
  });

  test('CASE 5 no duplicate: does not invent type overlap', () {
    final roster = [member('Pikachu', PokeType.electric, 40),
      member('Squirtle', PokeType.water, 90)];
    expect(TeamAdvisor.identifiesTypeOverlap(roster), isFalse);
  });

  test('undecided role gives editable suggestion', () {
    final roster = [member('Eevee', PokeType.normal, 55,
      role: 'Undecided', id: 3)];
    expect(TeamAdvisor.advise(roster).any((t) =>
      t.key == 'role-3' && t.actionType == CoachAction.editMember), isTrue);
  });

  test('a full roster advises review, not a seventh slot', () {
    final roster = List.generate(6, (i) => member('Eevee', PokeType.normal,
      60, id: i + 1));
    final tips = TeamAdvisor.advise(roster);
    expect(tips.any((t) => t.key == 'open-slots'), isFalse);
    final overlap = tips.firstWhere((t) => t.key == 'type-normal');
    expect(overlap.actionType, CoachAction.editMember);
  });
}
