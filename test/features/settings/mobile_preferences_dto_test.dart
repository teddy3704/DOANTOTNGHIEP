import 'package:dlu_lms_mobile/features/settings/data/mobile_preferences_dto.dart';
import 'package:dlu_lms_mobile/features/settings/domain/mobile_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ownerId = '11111111-1111-4111-8111-111111111111';

  test('maps a validated Supabase row to the domain model', () {
    final dto = MobilePreferencesDto.fromJson(<String, Object?>{
      'owner_id': ownerId,
      'theme_mode': 'dark',
      'created_at': '2026-08-16T01:00:00+07:00',
      'updated_at': '2026-08-16T02:30:00+07:00',
    });

    final model = dto.toDomain();
    expect(model.ownerId, ownerId);
    expect(model.themeMode, PreferredThemeMode.dark);
    expect(model.createdAt.isUtc, isTrue);
    expect(model.updatedAt.isUtc, isTrue);
  });

  test('rejects malformed, foreign-shaped, or unsupported rows', () {
    final invalidRows = <Map<String, Object?>>[
      <String, Object?>{
        'owner_id': 'not-a-uuid',
        'theme_mode': 'system',
        'created_at': '2026-08-16T00:00:00Z',
        'updated_at': '2026-08-16T00:00:00Z',
      },
      <String, Object?>{
        'owner_id': ownerId,
        'theme_mode': 'amoled',
        'created_at': '2026-08-16T00:00:00Z',
        'updated_at': '2026-08-16T00:00:00Z',
      },
      <String, Object?>{
        'owner_id': ownerId,
        'theme_mode': 'light',
        'created_at': 'not-a-time',
        'updated_at': '2026-08-16T00:00:00Z',
      },
    ];

    for (final row in invalidRows) {
      expect(() => MobilePreferencesDto.fromJson(row), throwsFormatException);
    }
  });
}
