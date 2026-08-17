import 'package:dlu_lms_mobile/core/auth/supabase_identity_session.dart';
import 'package:dlu_lms_mobile/core/config/supabase_config.dart';
import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/core/network/supabase_client_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = SupabaseConfig(
    projectUri: Uri.parse('https://project-ref.supabase.co'),
    publishableKey: 'sb_publishable_unit_test_value',
  );

  test(
    'client factory obtains a JWT from the injected identity session',
    () async {
      final client = const SupabaseClientFactory().create(
        config: config,
        identitySession: _FakeIdentitySession(
          accessToken: 'unit-test-access-value',
          identity: _authenticatedIdentity,
        ),
      );
      addTearDown(client.dispose);

      expect(await client.accessToken!(), 'unit-test-access-value');
    },
  );

  test('client factory rejects a missing authenticated access token', () async {
    final client = const SupabaseClientFactory().create(
      config: config,
      identitySession: _FakeIdentitySession(
        accessToken: null,
        identity: _authenticatedIdentity,
      ),
    );
    addTearDown(client.dispose);

    expect(
      client.accessToken!(),
      throwsA(
        isA<AuthenticationFailure>().having(
          (failure) => failure.code,
          'code',
          'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
        ),
      ),
    );
  });

  test('client factory rejects anonymous identity before returning a JWT', () {
    final client = const SupabaseClientFactory().create(
      config: config,
      identitySession: _FakeIdentitySession(
        accessToken: 'unit-test-access-value',
        identity: SupabaseIdentity(
          userId: '11111111-1111-4111-8111-111111111111',
          isAnonymous: true,
        ),
      ),
    );
    addTearDown(client.dispose);

    expect(
      client.accessToken!(),
      throwsA(
        isA<AuthenticationFailure>().having(
          (failure) => failure.code,
          'code',
          'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
        ),
      ),
    );
  });
}

final _authenticatedIdentity = SupabaseIdentity(
  userId: '11111111-1111-4111-8111-111111111111',
  isAnonymous: false,
);

final class _FakeIdentitySession implements SupabaseIdentitySession {
  const _FakeIdentitySession({
    required this.accessToken,
    required this.identity,
  });

  final String? accessToken;
  final SupabaseIdentity? identity;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<SupabaseIdentity?> readIdentity() async => identity;
}
