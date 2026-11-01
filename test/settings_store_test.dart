import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poketran/data/models.dart';
import 'package:poketran/data/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('default settings are dark mode and visible coach', () async {
    final settings = await const SettingsStore().read();
    expect(settings.darkMode, isTrue);
    expect(settings.showHints, isTrue);
  });

  test('both settings survive reads from fresh store instances', () async {
    await const SettingsStore().save('darkMode', false);
    await const SettingsStore().save('showHints', false);
    final settings = await const SettingsStore().read();
    expect(settings.darkMode, isFalse);
    expect(settings.showHints, isFalse);
  });

  test('unknown setting is rejected', () async {
    await expectLater(const SettingsStore().save('password', true),
      throwsA(isA<ValidationException>()));
  });
}
