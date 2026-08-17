import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_failure.dart';

final class SupabaseIdentity {
  SupabaseIdentity({required this.userId, required this.isAnonymous}) {
    if (!_uuidPattern.hasMatch(userId)) {
      throw ArgumentError('Supabase identity must use a UUID subject.');
    }
  }

  final String userId;
  final bool isAnonymous;

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
}

abstract interface class SupabaseIdentitySession {
  Future<String?> readAccessToken();

  Future<SupabaseIdentity?> readIdentity();
}

final class UnconfiguredSupabaseIdentitySession
    implements SupabaseIdentitySession {
  const UnconfiguredSupabaseIdentitySession();

  @override
  Future<String?> readAccessToken() {
    throw const ConfigurationFailure(
      'Liên kết danh tính DLU với dịch vụ dữ liệu chưa được cấu hình.',
      code: 'SUPABASE_IDENTITY_MAPPING_REQUIRED',
    );
  }

  @override
  Future<SupabaseIdentity?> readIdentity() {
    throw const ConfigurationFailure(
      'Liên kết danh tính DLU với dịch vụ dữ liệu chưa được cấu hình.',
      code: 'SUPABASE_IDENTITY_MAPPING_REQUIRED',
    );
  }
}

final supabaseIdentitySessionProvider = Provider<SupabaseIdentitySession>(
  (ref) => const UnconfiguredSupabaseIdentitySession(),
);
