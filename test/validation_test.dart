import 'package:flutter_test/flutter_test.dart';
import 'package:poketran/data/models.dart';

void main() {
  test('valid team passes', () {
    expect(() => DomainValidation.team(const TeamRecord(
      name: 'Kanto Stars', goal: 'Train for the league', region: 'Kanto')),
      returnsNormally);
  });

  test('rejects empty goal and short team name', () {
    expect(() => DomainValidation.team(const TeamRecord(
      name: 'A', goal: 'X', region: 'Kanto')),
      throwsA(isA<ValidationException>()));
    expect(() => DomainValidation.team(const TeamRecord(
      name: 'Stars', goal: ' ', region: 'Kanto')),
      throwsA(isA<ValidationException>()));
  });

  PokeMember sample({int level = 25, int progress = 40}) => PokeMember(
    teamId: 1, species: 'Pikachu', nickname: '', type: PokeType.electric,
    role: 'Attacker', level: level, progress: progress, notes: 'Fast move user');

  test('valid member passes', () {
    expect(() => DomainValidation.member(sample()), returnsNormally);
  });

  test('rejects levels out of bounds', () {
    expect(() => DomainValidation.member(sample(level: 0)),
      throwsA(isA<ValidationException>()));
    expect(() => DomainValidation.member(sample(level: 101)),
      throwsA(isA<ValidationException>()));
  });

  test('rejects progress above 100', () {
    expect(() => DomainValidation.member(sample(progress: 101)),
      throwsA(isA<ValidationException>()));
  });
}
