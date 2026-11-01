import 'package:flutter/material.dart';
import '../data/models.dart';

const brandBlue = Color(0xFF6D7CFF);
const brandYellow = Color(0xFFFFCC5C);
const darkCanvas = Color(0xFF0C1020);
const darkSurface = Color(0xFF171D33);

ThemeData appTheme(bool dark) {
  final seed = brandBlue;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: dark ? darkSurface : const Color(0xFFF8F9FF),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? darkCanvas : const Color(0xFFF3F5FF),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? darkCanvas : const Color(0xFFF3F5FF),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? darkSurface : Colors.white,
      indicatorColor: brandBlue.withValues(alpha: 0.22),
    ),
  );
}

Color typeColor(PokeType type) => switch (type) {
  PokeType.normal => const Color(0xFF9EA0A7),
  PokeType.fire => const Color(0xFFFD784C),
  PokeType.water => const Color(0xFF4E9BFA),
  PokeType.electric => const Color(0xFFFFC94D),
  PokeType.grass => const Color(0xFF4DC99B),
  PokeType.ice => const Color(0xFF6FCFD4),
  PokeType.fighting => const Color(0xFFE16E61),
  PokeType.poison => const Color(0xFFAB72F3),
  PokeType.ground => const Color(0xFFC79562),
  PokeType.flying => const Color(0xFF96A4E8),
  PokeType.psychic => const Color(0xFFF66FAD),
  PokeType.bug => const Color(0xFF99BE56),
  PokeType.rock => const Color(0xFFB39B69),
  PokeType.ghost => const Color(0xFF7A72C2),
  PokeType.dragon => const Color(0xFF6877EE),
  PokeType.dark => const Color(0xFF68616D),
  PokeType.steel => const Color(0xFF8DAFBA),
  PokeType.fairy => const Color(0xFFF1A0D4),
};

String typeEmoji(PokeType type) => switch (type) {
  PokeType.normal => '◉', PokeType.fire => '🔥',
  PokeType.water => '💧', PokeType.electric => '⚡',
  PokeType.grass => '🌿', PokeType.ice => '❄️',
  PokeType.fighting => '🥊', PokeType.poison => '☠️',
  PokeType.ground => '⛰️', PokeType.flying => '🪽',
  PokeType.psychic => '🔮', PokeType.bug => '🐛',
  PokeType.rock => '🪨', PokeType.ghost => '👻',
  PokeType.dragon => '🐉', PokeType.dark => '🌙',
  PokeType.steel => '⚙️', PokeType.fairy => '✨',
};
