import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// SQLite is the source of truth. No Firebase, PokeAPI, or web services.
class DatabaseService {
  DatabaseService._() : _customDatabasePath = null;

  /// Test-only instance; use an in-memory path to leave user data untouched.
  DatabaseService.testing(String databasePath) : _customDatabasePath = databasePath;

  final String? _customDatabasePath;
  static final DatabaseService instance = DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final filePath = _customDatabasePath ??
        p.join(await getDatabasesPath(), 'poketran.db');
    _db = await openDatabase(
      filePath,
      version: 2,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE teams (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            goal TEXT NOT NULL,
            region TEXT NOT NULL,
            status TEXT NOT NULL CHECK(status IN ('planned','active','complete')),
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pokemon (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            team_id INTEGER NOT NULL,
            species TEXT NOT NULL,
            nickname TEXT NOT NULL DEFAULT '',
            type TEXT NOT NULL,
            role TEXT NOT NULL,
            level INTEGER NOT NULL CHECK(level BETWEEN 1 AND 100),
            progress INTEGER NOT NULL CHECK(progress BETWEEN 0 AND 100),
            notes TEXT NOT NULL DEFAULT '',
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_pokemon_team ON pokemon(team_id)');
        await db.execute('''
          CREATE TABLE activity (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            detail TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE coach_feedback (
            team_id INTEGER NOT NULL,
            tip_key TEXT NOT NULL,
            decision TEXT NOT NULL CHECK(decision IN ('not_now','apply')),
            updated_at INTEGER NOT NULL,
            PRIMARY KEY(team_id, tip_key),
            FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE preferences (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE coach_feedback (
              team_id INTEGER NOT NULL,
              tip_key TEXT NOT NULL,
              decision TEXT NOT NULL CHECK(decision IN ('not_now','apply')),
              updated_at INTEGER NOT NULL,
              PRIMARY KEY(team_id, tip_key),
              FOREIGN KEY(team_id) REFERENCES teams(id) ON DELETE CASCADE
            )
          ''' );
        }
      },
    );
    return _db!;
  }

  Future<List<TeamRecord>> getTeams() async {
    final db = await database;
    final rows = await db.query('teams', orderBy: 'updated_at DESC, id DESC');
    return rows.map(TeamRecord.fromMap).toList();
  }

  Future<TeamRecord?> getTeam(int id) async {
    final db = await database;
    final rows = await db.query('teams', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : TeamRecord.fromMap(rows.first);
  }

  Future<List<PokeMember>> getMembers(int teamId) async {
    final db = await database;
    final rows = await db.query('pokemon', where: 'team_id = ?',
        whereArgs: [teamId], orderBy: 'created_at ASC, id ASC');
    return rows.map(PokeMember.fromMap).toList();
  }

  Future<List<PokeMember>> getAllMembers() async {
    final db = await database;
    final rows = await db.query('pokemon', orderBy: 'updated_at DESC');
    return rows.map(PokeMember.fromMap).toList();
  }

  Future<List<ActivityEntry>> getActivity({int limit = 60}) async {
    final db = await database;
    final rows = await db.query('activity', orderBy: 'created_at DESC, id DESC', limit: limit);
    return rows.map(ActivityEntry.fromMap).toList();
  }

  Future<void> _log(Transaction txn, String title, String detail) async {
    await txn.insert('activity', {
      'title': title,
      'detail': detail,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<int> saveTeam(TeamRecord team) async {
    DomainValidation.team(team);
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction((txn) async {
      if (team.id == null) {
        final id = await txn.insert('teams', {
          'name': team.name.trim(), 'goal': team.goal.trim(),
          'region': team.region.trim(), 'status': TeamStatus.planned.name,
          'created_at': now, 'updated_at': now,
        });
        await _log(txn, 'Team created', '${team.name.trim()} is ready to build.');
        return id;
      }
      final changed = await txn.update('teams', {
        'name': team.name.trim(), 'goal': team.goal.trim(),
        'region': team.region.trim(), 'updated_at': now,
      }, where: 'id = ?', whereArgs: [team.id]);
      if (changed == 0) throw const ValidationException('This team no longer exists.');
      await _log(txn, 'Team edited', '${team.name.trim()} details were updated.');
      return team.id!;
    });
  }

  Future<void> deleteTeam(int teamId) async {
    final db = await database;
    await db.transaction((txn) async {
      final matches = await txn.query('teams', where: 'id = ?', whereArgs: [teamId]);
      if (matches.isEmpty) throw const ValidationException('Team not found.');
      final name = matches.first['name'] as String;
      await txn.delete('teams', where: 'id = ?', whereArgs: [teamId]);
      // PRAGMA foreign_keys cascades deletions to all child Pokemon.
      await _log(txn, 'Team deleted', '$name and its roster were removed.');
    });
  }

  Future<int> saveMember(PokeMember member) async {
    DomainValidation.member(member);
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction((txn) async {
      final teams = await txn.query('teams', where: 'id = ?', whereArgs: [member.teamId]);
      if (teams.isEmpty) throw const ValidationException('Team not found.');
      final teamName = teams.first['name'] as String;
      if (teams.first['status'] == TeamStatus.complete.name) {
        throw const ValidationException('Reset a completed team before editing its roster.');
      }
      if (member.id == null) {
        final count = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM pokemon WHERE team_id = ?', [member.teamId])) ?? 0;
        if (count >= 6) throw const ValidationException('A team can hold at most six Pokémon.');
        final id = await txn.insert('pokemon', {
          'team_id': member.teamId, 'species': member.species.trim(),
          'nickname': member.nickname.trim(), 'type': member.type.name,
          'role': member.role.trim(), 'level': member.level,
          'progress': member.progress, 'notes': member.notes.trim(),
          'created_at': now, 'updated_at': now,
        });
        await txn.update('teams', {'updated_at': now}, where: 'id = ?', whereArgs: [member.teamId]);
        await txn.delete('coach_feedback', where: 'team_id = ?', whereArgs: [member.teamId]);
        await _log(txn, 'Pokémon recruited', '${member.species.trim()} joined $teamName.');
        return id;
      }
      final changed = await txn.update('pokemon', {
        'species': member.species.trim(), 'nickname': member.nickname.trim(),
        'type': member.type.name, 'role': member.role.trim(),
        'level': member.level, 'progress': member.progress,
        'notes': member.notes.trim(), 'updated_at': now,
      }, where: 'id = ? AND team_id = ?', whereArgs: [member.id, member.teamId]);
      if (changed == 0) throw const ValidationException('Pokémon not found.');
      await txn.update('teams', {'updated_at': now}, where: 'id = ?', whereArgs: [member.teamId]);
      await txn.delete('coach_feedback', where: 'team_id = ?', whereArgs: [member.teamId]);
      await _log(txn, 'Training logged', '${member.species.trim()} updated in $teamName.');
      return member.id!;
    });
  }

  Future<void> deleteMember(PokeMember member) async {
    if (member.id == null) return;
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final teams = await txn.query('teams', where: 'id = ?', whereArgs: [member.teamId]);
      if (teams.isEmpty) throw const ValidationException('Team not found.');
      if (teams.first['status'] == TeamStatus.complete.name) {
        throw const ValidationException('Reset a completed team before releasing Pokémon.');
      }
      final changed = await txn.delete('pokemon', where: 'id = ? AND team_id = ?',
          whereArgs: [member.id, member.teamId]);
      if (changed == 0) throw const ValidationException('Pokémon not found.');
      await txn.update('teams', {'updated_at': now}, where: 'id = ?', whereArgs: [member.teamId]);
      await txn.delete('coach_feedback', where: 'team_id = ?', whereArgs: [member.teamId]);
      await _log(txn, 'Pokémon released', '${member.species} was removed from the roster.');
    });
  }

  Future<void> changeStatus(int teamId, TeamStatus target) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final matches = await txn.query('teams', where: 'id = ?', whereArgs: [teamId]);
      if (matches.isEmpty) throw const ValidationException('Team not found.');
      final current = TeamStatus.values.byName(matches.first['status'] as String);
      if (target == TeamStatus.active) {
        if (current != TeamStatus.planned) {
          throw const ValidationException('Only a planned team can start training.');
        }
        final count = Sqflite.firstIntValue(await txn.rawQuery(
          'SELECT COUNT(*) FROM pokemon WHERE team_id = ?', [teamId])) ?? 0;
        if (count == 0) {
          throw const ValidationException('Recruit at least one Pokémon before training.');
        }
      }
      if (target == TeamStatus.complete) {
        if (current != TeamStatus.active) {
          throw const ValidationException('Start training before completing your team.');
        }
        final roster = await txn.query('pokemon', where: 'team_id = ?', whereArgs: [teamId]);
        if (roster.isEmpty || roster.any((p) => (p['progress'] as int) < 100)) {
          throw const ValidationException('Finish training every Pokémon to 100% first.');
        }
      }
      if (target == TeamStatus.planned) {
        throw const ValidationException('Use Reset team to return to planning.');
      }
      await txn.update('teams', {'status': target.name, 'updated_at': now},
          where: 'id = ?', whereArgs: [teamId]);
      await txn.delete('coach_feedback', where: 'team_id = ?', whereArgs: [teamId]);
      await _log(txn, target == TeamStatus.active ? 'Training started' : 'Team completed',
          '${matches.first['name']} — ${target.label}.');
    });
  }

  Future<void> resetTeam(int teamId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final matches = await txn.query('teams', where: 'id = ?', whereArgs: [teamId]);
      if (matches.isEmpty) throw const ValidationException('Team not found.');
      await txn.update('teams', {'status': TeamStatus.planned.name, 'updated_at': now},
          where: 'id = ?', whereArgs: [teamId]);
      await txn.update('pokemon', {'progress': 0, 'updated_at': now},
          where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('coach_feedback', where: 'team_id = ?', whereArgs: [teamId]);
      await _log(txn, 'Team reset', '${matches.first['name']} progress reset to zero.');
    });
  }

  Future<Set<String>> getDismissedCoachTips(int teamId) async {
    final db = await database;
    final rows = await db.query('coach_feedback', columns: ['tip_key'],
        where: 'team_id = ? AND decision = ?', whereArgs: [teamId, 'not_now']);
    return rows.map((r) => r['tip_key'] as String).toSet();
  }

  /// A coach choice is persisted so it remains meaningful after a restart.
  Future<void> recordCoachChoice(int teamId, String tipKey, String choice) async {
    if (tipKey.isEmpty || !['not_now', 'apply'].contains(choice)) {
      throw const ValidationException('Invalid coach choice.');
    }
    final db = await database;
    await db.transaction((txn) async {
      final team = await txn.query('teams', where: 'id = ?', whereArgs: [teamId]);
      if (team.isEmpty) throw const ValidationException('Team not found.');
      await txn.insert('coach_feedback', {
        'team_id': teamId, 'tip_key': tipKey, 'decision': choice,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _log(txn, 'Coach choice',
          '${choice == 'not_now' ? 'Not now' : 'Apply'}: $tipKey');
    });
  }

  Future<void> revealCoachTips(int teamId) async {
    final db = await database;
    await db.delete('coach_feedback',
        where: 'team_id = ? AND decision = ?', whereArgs: [teamId, 'not_now']);
  }

  /// Creates a clearly labeled fictional sample that is fully stored offline.
  /// This is optional data for demonstrating CRUD, the progress workflow,
  /// type-overlap suggestions, aggregates, and activity history.
  Future<int> createDemoTeam() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction((txn) async {
      final id = await txn.insert('teams', {
        'name': 'Kanto Showcase',
        'goal': 'Prepare a balanced team for the Indigo League.',
        'region': 'Kanto',
        'status': TeamStatus.active.name,
        'created_at': now,
        'updated_at': now,
      });
      final sample = <(String, PokeType, String, int, int, String)>[
        ('Pikachu', PokeType.electric, 'Speed attacker', 36, 75, 'Thunderbolt and quick switches.'),
        ('Charizard', PokeType.fire, 'Special attacker', 42, 50, 'Focus on damage and coverage.'),
        ('Arcanine', PokeType.fire, 'Physical attacker', 40, 25, 'Overlap with Charizard is a teaching point.'),
        ('Blastoise', PokeType.water, 'Tank', 43, 90, 'Defensive anchor of the lineup.'),
        ('Venusaur', PokeType.grass, 'Support', 41, 60, 'Status and recovery specialist.'),
        ('Gengar', PokeType.ghost, 'Fast disruptor', 38, 10, 'Train this Pokémon next.'),
      ];
      for (final (species, type, role, level, progress, notes) in sample) {
        await txn.insert('pokemon', {
          'team_id': id,
          'species': species,
          'nickname': '',
          'type': type.name,
          'role': role,
          'level': level,
          'progress': progress,
          'notes': notes,
          'created_at': now,
          'updated_at': now,
        });
      }
      await _log(txn, 'Demo team created',
          'Kanto Showcase added with six Pokémon and sample training progress.');
      return id;
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
