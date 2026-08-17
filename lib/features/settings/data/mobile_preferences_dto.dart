import '../domain/mobile_preferences.dart';

final class MobilePreferencesDto {
  const MobilePreferencesDto({
    required this.ownerId,
    required this.themeMode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MobilePreferencesDto.fromJson(Map<String, Object?> json) {
    final ownerId = json['owner_id'];
    final rawThemeMode = json['theme_mode'];
    final rawCreatedAt = json['created_at'];
    final rawUpdatedAt = json['updated_at'];

    if (ownerId is! String || !_uuidPattern.hasMatch(ownerId)) {
      throw const FormatException('Invalid mobile preferences owner.');
    }
    if (rawThemeMode is! String) {
      throw const FormatException('Invalid mobile preferences theme mode.');
    }
    if (rawCreatedAt is! String || rawUpdatedAt is! String) {
      throw const FormatException('Invalid mobile preferences timestamps.');
    }

    final createdAt = DateTime.tryParse(rawCreatedAt);
    final updatedAt = DateTime.tryParse(rawUpdatedAt);
    if (createdAt == null || updatedAt == null) {
      throw const FormatException('Invalid mobile preferences timestamps.');
    }

    return MobilePreferencesDto(
      ownerId: ownerId,
      themeMode: _decodeThemeMode(rawThemeMode),
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }

  final String ownerId;
  final PreferredThemeMode themeMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  MobilePreferences toDomain() => MobilePreferences(
    ownerId: ownerId,
    themeMode: themeMode,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static PreferredThemeMode _decodeThemeMode(String value) {
    return switch (value) {
      'system' => PreferredThemeMode.system,
      'light' => PreferredThemeMode.light,
      'dark' => PreferredThemeMode.dark,
      _ => throw const FormatException(
        'Unsupported mobile preferences theme mode.',
      ),
    };
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
}
