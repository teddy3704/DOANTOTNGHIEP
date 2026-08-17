import 'package:dlu_lms_mobile/core/auth/supabase_identity_session.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/settings/data/mobile_preferences_remote_data_source.dart';
import 'package:dlu_lms_mobile/features/settings/domain/mobile_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const ownerId = '11111111-1111-4111-8111-111111111111';
  const otherOwnerId = '22222222-2222-4222-8222-222222222222';

  test('queries only the authenticated owner and maps the row', () async {
    final gateway = _FakeGateway(row: _row(ownerId));
    final dataSource = SupabaseMobilePreferencesRemoteDataSource(
      gateway: gateway,
      identitySession: _FakeIdentitySession(
        SupabaseIdentity(userId: ownerId, isAnonymous: false),
      ),
    );

    final result = await dataSource.fetchForCurrentUser();

    expect(result?.ownerId, ownerId);
    expect(gateway.lastOwnerId, ownerId);
    expect(gateway.fetchCount, 1);
  });

  test('rejects anonymous identity before any table request', () async {
    final gateway = _FakeGateway(row: _row(ownerId));
    final dataSource = SupabaseMobilePreferencesRemoteDataSource(
      gateway: gateway,
      identitySession: _FakeIdentitySession(
        SupabaseIdentity(userId: ownerId, isAnonymous: true),
      ),
    );

    expect(
      dataSource.fetchForCurrentUser(),
      throwsA(
        isA<AuthenticationFailure>().having(
          (failure) => failure.code,
          'code',
          'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
        ),
      ),
    );
    expect(gateway.fetchCount, 0);
  });

  test('rejects a missing identity before any table request', () async {
    final gateway = _FakeGateway(row: _row(ownerId));
    final dataSource = SupabaseMobilePreferencesRemoteDataSource(
      gateway: gateway,
      identitySession: const _FakeIdentitySession(null),
    );

    expect(
      dataSource.fetchForCurrentUser(),
      throwsA(
        isA<AuthenticationFailure>().having(
          (failure) => failure.code,
          'code',
          'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
        ),
      ),
    );
    expect(gateway.fetchCount, 0);
  });

  test('rejects a row that does not belong to the active identity', () async {
    final gateway = _FakeGateway(row: _row(otherOwnerId));
    final dataSource = SupabaseMobilePreferencesRemoteDataSource(
      gateway: gateway,
      identitySession: _FakeIdentitySession(
        SupabaseIdentity(userId: ownerId, isAnonymous: false),
      ),
    );

    expect(
      dataSource.fetchForCurrentUser(),
      throwsA(
        isA<PermissionFailure>().having(
          (failure) => failure.code,
          'code',
          'SUPABASE_OWNERSHIP_MISMATCH',
        ),
      ),
    );
  });

  test('saves only the authenticated owner theme preference', () async {
    final gateway = _FakeGateway(row: _row(ownerId, themeMode: 'light'));
    final dataSource = SupabaseMobilePreferencesRemoteDataSource(
      gateway: gateway,
      identitySession: _FakeIdentitySession(
        SupabaseIdentity(userId: ownerId, isAnonymous: false),
      ),
    );

    final result = await dataSource.saveThemeMode(PreferredThemeMode.light);

    expect(result.themeMode, PreferredThemeMode.light);
    expect(gateway.fetchCount, 0);
    expect(gateway.saveCount, 1);
    expect(gateway.lastOwnerId, isNull);
    expect(gateway.lastThemeMode, PreferredThemeMode.light);
  });

  test('maps invalid response data without leaking raw transport errors', () {
    final gateway = _FakeGateway(
      row: <String, Object?>{..._row(ownerId), 'theme_mode': 'unsupported'},
    );
    final dataSource = SupabaseMobilePreferencesRemoteDataSource(
      gateway: gateway,
      identitySession: _FakeIdentitySession(
        SupabaseIdentity(userId: ownerId, isAnonymous: false),
      ),
    );

    expect(
      dataSource.fetchForCurrentUser(),
      throwsA(
        isA<ParsingFailure>().having(
          (failure) => failure.code,
          'code',
          'SUPABASE_INVALID_RESPONSE',
        ),
      ),
    );
  });

  test('maps RLS denial to a permission failure', () {
    final gateway = _FakeGateway(
      row: null,
      error: const PostgrestException(
        message: 'raw database permission detail',
        code: '42501',
      ),
    );
    final dataSource = SupabaseMobilePreferencesRemoteDataSource(
      gateway: gateway,
      identitySession: _FakeIdentitySession(
        SupabaseIdentity(userId: ownerId, isAnonymous: false),
      ),
    );

    expect(
      dataSource.fetchForCurrentUser(),
      throwsA(
        isA<PermissionFailure>()
            .having((failure) => failure.code, 'code', 'SUPABASE_RLS_DENIED')
            .having(
              (failure) => failure.message,
              'sanitized message',
              isNot(contains('raw database')),
            ),
      ),
    );
  });

  test(
    'maps stable Data API codes to sanitized application failures',
    () async {
      final cases = <({String postgrestCode, Type type, String appCode})>[
        (
          postgrestCode: 'PGRST301',
          type: AuthenticationFailure,
          appCode: 'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
        ),
        (
          postgrestCode: 'PGRST000',
          type: ServerFailure,
          appCode: 'SUPABASE_SERVICE_UNAVAILABLE',
        ),
        (
          postgrestCode: 'PGRST003',
          type: TimeoutFailure,
          appCode: 'SUPABASE_REQUEST_TIMEOUT',
        ),
        (
          postgrestCode: '429',
          type: ServerFailure,
          appCode: 'SUPABASE_RATE_LIMITED',
        ),
      ];

      for (final testCase in cases) {
        final dataSource = SupabaseMobilePreferencesRemoteDataSource(
          gateway: _FakeGateway(
            row: null,
            error: PostgrestException(
              message: 'raw backend diagnostic',
              code: testCase.postgrestCode,
            ),
          ),
          identitySession: _FakeIdentitySession(
            SupabaseIdentity(userId: ownerId, isAnonymous: false),
          ),
        );

        await expectLater(
          dataSource.fetchForCurrentUser(),
          throwsA(
            isA<AppFailure>()
                .having(
                  (failure) => failure.runtimeType,
                  'failure type',
                  testCase.type,
                )
                .having(
                  (failure) => failure.code,
                  'stable code',
                  testCase.appCode,
                )
                .having(
                  (failure) => failure.message,
                  'sanitized message',
                  isNot(contains('raw backend')),
                ),
          ),
        );
      }
    },
  );

  test('maps timeout to a stable application failure', () {
    final gateway = _FakeGateway(
      row: _row(ownerId),
      delay: const Duration(milliseconds: 30),
    );
    final dataSource = SupabaseMobilePreferencesRemoteDataSource(
      gateway: gateway,
      identitySession: _FakeIdentitySession(
        SupabaseIdentity(userId: ownerId, isAnonymous: false),
      ),
      timeout: const Duration(milliseconds: 1),
    );

    expect(
      dataSource.fetchForCurrentUser(),
      throwsA(
        isA<TimeoutFailure>().having(
          (failure) => failure.code,
          'code',
          'SUPABASE_REQUEST_TIMEOUT',
        ),
      ),
    );
  });

  test('sanitizes generic Data API and client exceptions', () async {
    final errors = <Exception>[
      const PostgrestException(
        message: 'raw backend table detail',
        code: 'PGRST999',
      ),
      Exception('raw SDK transport detail'),
    ];

    for (final error in errors) {
      final dataSource = SupabaseMobilePreferencesRemoteDataSource(
        gateway: _FakeGateway(row: null, error: error),
        identitySession: _FakeIdentitySession(
          SupabaseIdentity(userId: ownerId, isAnonymous: false),
        ),
      );

      await expectLater(
        dataSource.fetchForCurrentUser(),
        throwsA(
          isA<ServerFailure>()
              .having(
                (failure) => failure.code,
                'stable code',
                anyOf('SUPABASE_DATA_API_ERROR', 'SUPABASE_CLIENT_ERROR'),
              )
              .having(
                (failure) => failure.message,
                'sanitized message',
                allOf(
                  isNot(contains('raw backend')),
                  isNot(contains('raw SDK')),
                ),
              ),
        ),
      );
    }
  });
}

Map<String, Object?> _row(String ownerId, {String themeMode = 'system'}) {
  return <String, Object?>{
    'owner_id': ownerId,
    'theme_mode': themeMode,
    'created_at': '2026-08-16T00:00:00Z',
    'updated_at': '2026-08-16T00:00:00Z',
  };
}

final class _FakeIdentitySession implements SupabaseIdentitySession {
  const _FakeIdentitySession(this.identity);

  final SupabaseIdentity? identity;

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<SupabaseIdentity?> readIdentity() async => identity;
}

final class _FakeGateway implements MobilePreferencesSupabaseGateway {
  _FakeGateway({required this.row, this.error, this.delay});

  final Map<String, Object?>? row;
  final Exception? error;
  final Duration? delay;
  int fetchCount = 0;
  int saveCount = 0;
  String? lastOwnerId;
  PreferredThemeMode? lastThemeMode;

  @override
  Future<Map<String, Object?>?> fetchOwnRow({required String ownerId}) async {
    fetchCount += 1;
    lastOwnerId = ownerId;
    final requestDelay = delay;
    if (requestDelay != null) {
      await Future<void>.delayed(requestDelay);
    }
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    return row;
  }

  @override
  Future<Map<String, Object?>> saveOwnThemeMode(
    PreferredThemeMode themeMode,
  ) async {
    saveCount += 1;
    lastThemeMode = themeMode;
    return row!;
  }
}
