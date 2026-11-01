import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:poketran/data/database_service.dart';
import 'package:poketran/data/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseService db;

  setUp(() {
    db = DatabaseService.testing(inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  test('teams and child Pokémon support CRUD, then cascading delete', () async {
    final id = await db.saveTeam(const TeamRecord(
      name: 'Kanto Stars', goal: 'Train six Pokémon', region: 'Kanto'));
    expect((await db.getTeams()).length, 1);

    await db.saveMember(PokeMember(teamId: id, species: 'Pikachu',
      nickname: 'Sparky', type: PokeType.electric, role: 'Attacker',
      level: 40, progress: 25, notes: 'Fast attacker'));
    final member = (await db.getMembers(id)).single;
    expect(member.nickname, 'Sparky');
    expect(member.progress, 25);

    await db.saveMember(PokeMember(id: member.id, teamId: id, species: 'Pikachu',
      nickname: 'Sparky', type: PokeType.electric, role: 'Attacker',
      level: 41, progress: 100, notes: 'Trained'));
    expect((await db.getMembers(id)).single.progress, 100);

    await db.saveTeam(TeamRecord(id: id, name: 'Kanto Elite',
      goal: 'Win the league', region: 'Kanto'));
    expect((await db.getTeam(id))?.name, 'Kanto Elite');

    await db.changeStatus(id, TeamStatus.active);
    await db.changeStatus(id, TeamStatus.complete);
    expect((await db.getTeam(id))?.status, TeamStatus.complete);

    await expectLater(db.deleteMember(member),
        throwsA(isA<ValidationException>()));
    await db.resetTeam(id);
    expect((await db.getMembers(id)).single.progress, 0);
    await db.deleteMember(member);
    expect(await db.getMembers(id), isEmpty);

    await db.saveMember(PokeMember(teamId: id, species: 'Eevee',
      nickname: '', type: PokeType.normal, role: 'Support',
      level: 10, progress: 15, notes: ''));
    await db.deleteTeam(id);
    expect(await db.getTeam(id), isNull);
    expect(await db.getMembers(id), isEmpty);
    expect(await db.getAllMembers(), isEmpty);
  });

  test('prevents invalid transition and empty roster training', () async {
    final id = await db.saveTeam(const TeamRecord(
      name: 'Challenge', goal: 'Prepare team', region: 'Kanto'));
    await expectLater(db.changeStatus(id, TeamStatus.active),
      throwsA(isA<ValidationException>()));
    await db.saveMember(PokeMember(teamId: id, species: 'Psyduck',
      nickname: '', type: PokeType.water, role: 'Support',
      level: 12, progress: 15, notes: ''));
    await db.changeStatus(id, TeamStatus.active);
    await expectLater(db.changeStatus(id, TeamStatus.complete),
      throwsA(isA<ValidationException>()));
  });

  test('saves user decisions, supports reveal, and expires on roster edit', () async {
    final id = await db.saveTeam(const TeamRecord(
      name: 'Coach Study', goal: 'Explore recommendations', region: 'Kanto'));
    await db.saveMember(PokeMember(teamId: id, species: 'Vulpix',
      nickname: '', type: PokeType.fire, role: 'Attacker',
      level: 20, progress: 30, notes: ''));
    await db.recordCoachChoice(id, 'type-fire', 'not_now');
    expect(await db.getDismissedCoachTips(id), {'type-fire'});
    await db.revealCoachTips(id);
    expect(await db.getDismissedCoachTips(id), isEmpty);
    await db.recordCoachChoice(id, 'train-1', 'not_now');
    await db.saveMember(PokeMember(teamId: id, species: 'Growlithe',
      nickname: '', type: PokeType.fire, role: 'Support',
      level: 22, progress: 15, notes: ''));
    expect(await db.getDismissedCoachTips(id), isEmpty);
    expect((await db.getActivity()).any((e) => e.title == 'Coach choice'), isTrue);
  });

  test('prevents adding a seventh member', () async {
    final id = await db.saveTeam(const TeamRecord(
      name: 'Full party', goal: 'Fill six slots', region: 'Sinnoh'));
    for (var i = 0; i < 6; i++) {
      await db.saveMember(PokeMember(teamId: id, species: 'Eevee',
        nickname: 'E$i', type: PokeType.normal, role: 'Attacker',
        level: 10, progress: 0, notes: ''));
    }
    await expectLater(db.saveMember(PokeMember(teamId: id, species: 'Pikachu',
      nickname: '', type: PokeType.electric, role: 'Support',
      level: 10, progress: 0, notes: '')),
      throwsA(isA<ValidationException>()));
  });

  test('SQLite teams and coach decisions survive database reopen', () async {
    final dir = await Directory.systemTemp.createTemp('poketran-sql-test-');
    final path = p.join(dir.path, 'persistent.db');
    final first = DatabaseService.testing(path);
    try {
      final id = await first.saveTeam(const TeamRecord(
        name: 'Persistent team', goal: 'Verify restart', region: 'Johto'));
      await first.saveMember(PokeMember(teamId: id, species: 'Eevee',
        nickname: '', type: PokeType.normal, role: 'Support',
        level: 15, progress: 40, notes: 'Saved data'));
      await first.recordCoachChoice(id, 'open-slots', 'not_now');
      await first.close();
      final reopened = DatabaseService.testing(path);
      try {
        expect((await reopened.getTeams()).single.name, 'Persistent team');
        expect((await reopened.getMembers(id)).single.species, 'Eevee');
        expect(await reopened.getDismissedCoachTips(id), contains('open-slots'));
      } finally {
        await reopened.close();
      }
    } finally {
      await first.close();
      await dir.delete(recursive: true);
    }
  });

  test('sample team and activity records persist within local database', () async {
    await db.createDemoTeam();
    expect((await db.getTeams()).single.name, 'Kanto Showcase');
    expect((await db.getAllMembers()).length, 6);
    expect((await db.getActivity()).first.title, 'Demo team created');
  });
}
