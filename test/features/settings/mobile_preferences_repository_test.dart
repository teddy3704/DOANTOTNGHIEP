import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/settings/data/mobile_preferences_dto.dart';
import 'package:dlu_lms_mobile/features/settings/data/mobile_preferences_providers.dart';
import 'package:dlu_lms_mobile/features/settings/data/mobile_preferences_remote_data_source.dart';
import 'package:dlu_lms_mobile/features/settings/data/supabase_mobile_preferences_repository.dart';
import 'package:dlu_lms_mobile/features/settings/domain/mobile_preferences.dart';
import 'package:dlu_lms_mobile/features/settings/domain/mobile_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  const ownerId = '11111111-1111-4111-8111-111111111111';

  test('repository exposes typed domain preferences', () async {
    final repository = SupabaseMobilePreferencesRepository(
      _FakeRemoteDataSource(_dto(ownerId)),
    );

    final result = await repository.getForCurrentUser();

    expect(result?.ownerId, ownerId);
    expect(result?.themeMode, PreferredThemeMode.system);
  });

  test('unconfigured production repository fails closed', () {
    const repository = UnconfiguredMobilePreferencesRepository();

    for (final call in <Future<Object?> Function()>[
      repository.getForCurrentUser,
      () => repository.saveThemeMode(PreferredThemeMode.dark),
    ]) {
      expect(
        call,
        throwsA(
          isA<ConfigurationFailure>().having(
            (failure) => failure.code,
            'code',
            'SUPABASE_PROJECT_CONNECTION_REQUIRED',
          ),
        ),
      );
    }
  });

  test('default provider requires a connected Supabase project', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(mobilePreferencesRepositoryProvider),
      throwsA(
        isA<ConfigurationFailure>().having(
          (failure) => failure.code,
          'code',
          'SUPABASE_PROJECT_CONNECTION_REQUIRED',
        ),
      ),
    );
  });
}

MobilePreferencesDto _dto(String ownerId) => MobilePreferencesDto(
  ownerId: ownerId,
  themeMode: PreferredThemeMode.system,
  createdAt: DateTime.utc(2026, 8, 16),
  updatedAt: DateTime.utc(2026, 8, 16),
);

final class _FakeRemoteDataSource implements MobilePreferencesRemoteDataSource {
  const _FakeRemoteDataSource(this.dto);

  final MobilePreferencesDto dto;

  @override
  Future<MobilePreferencesDto?> fetchForCurrentUser() async => dto;

  @override
  Future<MobilePreferencesDto> saveThemeMode(
    PreferredThemeMode themeMode,
  ) async => dto;
}
