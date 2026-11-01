/// Core domain records. No network or cloud services are used.
enum TeamStatus { planned, active, complete }

enum PokeType {
  normal, fire, water, electric, grass, ice, fighting, poison, ground,
  flying, psychic, bug, rock, ghost, dragon, dark, steel, fairy,
}

extension PokeTypeDisplay on PokeType {
  String get label => name[0].toUpperCase() + name.substring(1);
}

extension TeamStatusDisplay on TeamStatus {
  String get label => switch (this) {
    TeamStatus.planned => 'Planning',
    TeamStatus.active => 'Training',
    TeamStatus.complete => 'Completed',
  };
}

class TeamRecord {
  final int? id;
  final String name;
  final String goal;
  final String region;
  final TeamStatus status;
  final int createdAt;
  final int updatedAt;

  const TeamRecord({
    this.id,
    required this.name,
    required this.goal,
    required this.region,
    this.status = TeamStatus.planned,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory TeamRecord.fromMap(Map<String, Object?> m) => TeamRecord(
    id: m['id'] as int,
    name: m['name'] as String,
    goal: m['goal'] as String,
    region: m['region'] as String,
    status: TeamStatus.values.byName(m['status'] as String),
    createdAt: m['created_at'] as int,
    updatedAt: m['updated_at'] as int,
  );
}

class PokeMember {
  final int? id;
  final int teamId;
  final String species;
  final String nickname;
  final PokeType type;
  final String role;
  final int level;
  final int progress;
  final String notes;
  final int createdAt;
  final int updatedAt;

  const PokeMember({
    this.id,
    required this.teamId,
    required this.species,
    required this.nickname,
    required this.type,
    required this.role,
    required this.level,
    required this.progress,
    required this.notes,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  factory PokeMember.fromMap(Map<String, Object?> m) => PokeMember(
    id: m['id'] as int,
    teamId: m['team_id'] as int,
    species: m['species'] as String,
    nickname: m['nickname'] as String,
    type: PokeType.values.byName(m['type'] as String),
    role: m['role'] as String,
    level: m['level'] as int,
    progress: m['progress'] as int,
    notes: m['notes'] as String,
    createdAt: m['created_at'] as int,
    updatedAt: m['updated_at'] as int,
  );

  String get displayName => nickname.trim().isEmpty ? species : nickname;
}

class ActivityEntry {
  final int id;
  final String title;
  final String detail;
  final int createdAt;

  const ActivityEntry({
    required this.id,
    required this.title,
    required this.detail,
    required this.createdAt,
  });

  factory ActivityEntry.fromMap(Map<String, Object?> m) => ActivityEntry(
    id: m['id'] as int,
    title: m['title'] as String,
    detail: m['detail'] as String,
    createdAt: m['created_at'] as int,
  );
}

class AppPreferences {
  final bool darkMode;
  final bool showHints;

  const AppPreferences({this.darkMode = true, this.showHints = true});
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => message;
}

class DomainValidation {
  static void team(TeamRecord team) {
    final name = team.name.trim();
    if (name.length < 2 || name.length > 40) {
      throw const ValidationException('Team name must have 2–40 characters.');
    }
    if (team.goal.trim().isEmpty || team.goal.trim().length > 180) {
      throw const ValidationException('Enter a team goal (up to 180 characters).');
    }
    if (team.region.trim().isEmpty || team.region.trim().length > 40) {
      throw const ValidationException('Enter a region (up to 40 characters).');
    }
  }

  static void member(PokeMember member) {
    final species = member.species.trim();
    if (species.length < 2 || species.length > 30) {
      throw const ValidationException('Pokémon species must have 2–30 characters.');
    }
    if (member.nickname.trim().length > 28) {
      throw const ValidationException('Nickname must be 28 characters or fewer.');
    }
    if (member.role.trim().isEmpty || member.role.trim().length > 50) {
      throw const ValidationException('Enter a role (up to 50 characters).');
    }
    if (member.level < 1 || member.level > 100) {
      throw const ValidationException('Level must be between 1 and 100.');
    }
    if (member.progress < 0 || member.progress > 100) {
      throw const ValidationException('Training progress must be between 0 and 100.');
    }
    if (member.notes.length > 240) {
      throw const ValidationException('Notes must be 240 characters or fewer.');
    }
    if (member.teamId <= 0) {
      throw const ValidationException('Select a valid team first.');
    }
  }
}
