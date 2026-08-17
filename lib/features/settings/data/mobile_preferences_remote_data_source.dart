import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/supabase_identity_session.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/mobile_preferences.dart';
import 'mobile_preferences_dto.dart';

abstract interface class MobilePreferencesRemoteDataSource {
  Future<MobilePreferencesDto?> fetchForCurrentUser();

  Future<MobilePreferencesDto> saveThemeMode(PreferredThemeMode themeMode);
}

abstract interface class MobilePreferencesSupabaseGateway {
  Future<Map<String, Object?>?> fetchOwnRow({required String ownerId});

  Future<Map<String, Object?>> saveOwnThemeMode(PreferredThemeMode themeMode);
}

final class SupabaseClientMobilePreferencesGateway
    implements MobilePreferencesSupabaseGateway {
  SupabaseClientMobilePreferencesGateway(this._client);

  static const _table = 'mobile_preferences';
  static const _columns = 'owner_id,theme_mode,created_at,updated_at';
  static const _saveThemeFunction = 'save_mobile_theme_preference';

  final SupabaseClient _client;

  @override
  Future<Map<String, Object?>?> fetchOwnRow({required String ownerId}) async {
    final row = await _client
        .from(_table)
        .select(_columns)
        .eq('owner_id', ownerId)
        .maybeSingle();
    return row?.cast<String, Object?>();
  }

  @override
  Future<Map<String, Object?>> saveOwnThemeMode(
    PreferredThemeMode themeMode,
  ) async {
    final row = await _client
        .rpc(
          _saveThemeFunction,
          params: <String, Object?>{'p_theme_mode': themeMode.name},
        )
        .single();
    return row.cast<String, Object?>();
  }
}

final class SupabaseMobilePreferencesRemoteDataSource
    implements MobilePreferencesRemoteDataSource {
  SupabaseMobilePreferencesRemoteDataSource({
    required MobilePreferencesSupabaseGateway gateway,
    required SupabaseIdentitySession identitySession,
    Duration timeout = const Duration(seconds: 15),
  }) : this._internal(gateway, identitySession, timeout);

  SupabaseMobilePreferencesRemoteDataSource._internal(
    this._gateway,
    this._identitySession,
    this._timeout,
  );

  final MobilePreferencesSupabaseGateway _gateway;
  final SupabaseIdentitySession _identitySession;
  final Duration _timeout;

  @override
  Future<MobilePreferencesDto?> fetchForCurrentUser() {
    return _guard(() async {
      final identity = await _requireAuthenticatedIdentity();
      final row = await _gateway
          .fetchOwnRow(ownerId: identity.userId)
          .timeout(_timeout);
      if (row == null) {
        return null;
      }
      return _parseOwnedRow(row, identity.userId);
    });
  }

  @override
  Future<MobilePreferencesDto> saveThemeMode(PreferredThemeMode themeMode) {
    return _guard(() async {
      final identity = await _requireAuthenticatedIdentity();
      final row = await _gateway.saveOwnThemeMode(themeMode).timeout(_timeout);
      return _parseOwnedRow(row, identity.userId);
    });
  }

  Future<SupabaseIdentity> _requireAuthenticatedIdentity() async {
    final identity = await _identitySession.readIdentity();
    if (identity == null || identity.isAnonymous) {
      throw const AuthenticationFailure(
        'Phiên truy cập dữ liệu ứng dụng chưa sẵn sàng.',
        code: 'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
      );
    }
    return identity;
  }

  MobilePreferencesDto _parseOwnedRow(
    Map<String, Object?> row,
    String expectedOwnerId,
  ) {
    final dto = MobilePreferencesDto.fromJson(row);
    if (dto.ownerId.toLowerCase() != expectedOwnerId.toLowerCase()) {
      throw const PermissionFailure(
        'Dữ liệu trả về không thuộc phiên người dùng hiện tại.',
        code: 'SUPABASE_OWNERSHIP_MISMATCH',
      );
    }
    return dto;
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AppFailure {
      rethrow;
    } on TimeoutException {
      throw const TimeoutFailure(
        'Dịch vụ dữ liệu ứng dụng đã hết thời gian chờ.',
        code: 'SUPABASE_REQUEST_TIMEOUT',
      );
    } on AuthException {
      throw const AuthenticationFailure(
        'Phiên truy cập dữ liệu ứng dụng không hợp lệ.',
        code: 'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
      );
    } on PostgrestException catch (error) {
      throw switch (error.code) {
        'PGRST301' || 'PGRST302' || 'PGRST303' => const AuthenticationFailure(
          'Phiên truy cập dữ liệu ứng dụng không hợp lệ.',
          code: 'SUPABASE_AUTHENTICATED_SESSION_REQUIRED',
        ),
        '42501' => const PermissionFailure(
          'Bạn không có quyền truy cập dữ liệu này.',
          code: 'SUPABASE_RLS_DENIED',
        ),
        'PGRST003' => const TimeoutFailure(
          'Dịch vụ dữ liệu ứng dụng đã hết thời gian chờ.',
          code: 'SUPABASE_REQUEST_TIMEOUT',
        ),
        'PGRST000' || 'PGRST001' || 'PGRST002' => const ServerFailure(
          'Dịch vụ dữ liệu ứng dụng tạm thời không khả dụng.',
          code: 'SUPABASE_SERVICE_UNAVAILABLE',
        ),
        '429' => const ServerFailure(
          'Có quá nhiều yêu cầu. Vui lòng thử lại sau.',
          code: 'SUPABASE_RATE_LIMITED',
        ),
        _ => const ServerFailure(
          'Dịch vụ dữ liệu ứng dụng đang gặp sự cố.',
          code: 'SUPABASE_DATA_API_ERROR',
        ),
      };
    } on FormatException {
      throw const ParsingFailure(
        'Dịch vụ dữ liệu ứng dụng trả về dữ liệu không hợp lệ.',
        code: 'SUPABASE_INVALID_RESPONSE',
      );
    } on TypeError {
      throw const ParsingFailure(
        'Dịch vụ dữ liệu ứng dụng trả về dữ liệu không hợp lệ.',
        code: 'SUPABASE_INVALID_RESPONSE',
      );
    } on Exception {
      throw const ServerFailure(
        'Dịch vụ dữ liệu ứng dụng đang gặp sự cố.',
        code: 'SUPABASE_CLIENT_ERROR',
      );
    }
  }
}
