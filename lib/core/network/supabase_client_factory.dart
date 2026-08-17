import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/supabase_identity_session.dart';
import '../config/supabase_config.dart';
import '../errors/app_failure.dart';

final class SupabaseClientFactory {
  const SupabaseClientFactory();

  SupabaseClient create({
    required SupabaseConfig config,
    required SupabaseIdentitySession identitySession,
  }) {
    return SupabaseClient(
      config.projectUri.toString(),
      config.publishableKey,
      accessToken: () => _requireAccessToken(identitySession),
    );
  }

  Future<String> _requireAccessToken(
    SupabaseIdentitySession identitySession,
  ) async {
    final identity = await identitySession.readIdentity();
    if (identity == null || identity.isAnonymous) {
      throw const AuthenticationFailure(
        'Phiên truy cập dữ liệu ứng dụng chưa sẵn sàng.',
        code: 'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
      );
    }

    final token = await identitySession.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw const AuthenticationFailure(
        'Phiên truy cập dữ liệu ứng dụng chưa sẵn sàng.',
        code: 'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
      );
    }
    return token;
  }
}

final supabaseClientFactoryProvider = Provider<SupabaseClientFactory>(
  (ref) => const SupabaseClientFactory(),
);

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = ref
      .watch(supabaseClientFactoryProvider)
      .create(
        config: ref.watch(supabaseConfigProvider),
        identitySession: ref.watch(supabaseIdentitySessionProvider),
      );
  ref.onDispose(() => unawaited(client.dispose()));
  return client;
});
