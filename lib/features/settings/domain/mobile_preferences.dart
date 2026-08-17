enum PreferredThemeMode { system, light, dark }

final class MobilePreferences {
  const MobilePreferences({
    required this.ownerId,
    required this.themeMode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String ownerId;
  final PreferredThemeMode themeMode;
  final DateTime createdAt;
  final DateTime updatedAt;
}
