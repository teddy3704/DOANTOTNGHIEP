import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_failure.dart';

final class SupabaseConfig {
  SupabaseConfig({required Uri projectUri, required String publishableKey})
    : projectUri = _normalizeProjectOrigin(projectUri),
      publishableKey = _validatePublishableKey(publishableKey);

  factory SupabaseConfig.fromEnvironment() {
    const projectUrl = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    if (projectUrl.isEmpty || publishableKey.isEmpty) {
      throw const ConfigurationFailure(
        'Dịch vụ dữ liệu ứng dụng chưa được kết nối.',
        code: 'SUPABASE_PROJECT_CONNECTION_REQUIRED',
      );
    }

    try {
      return SupabaseConfig(
        projectUri: Uri.parse(projectUrl),
        publishableKey: publishableKey,
      );
    } on FormatException {
      throw const ConfigurationFailure(
        'Cấu hình dịch vụ dữ liệu ứng dụng không hợp lệ.',
        code: 'SUPABASE_CONFIGURATION_INVALID',
      );
    } on ArgumentError {
      throw const ConfigurationFailure(
        'Cấu hình dịch vụ dữ liệu ứng dụng không hợp lệ.',
        code: 'SUPABASE_CONFIGURATION_INVALID',
      );
    }
  }

  final Uri projectUri;
  final String publishableKey;

  static Uri _normalizeProjectOrigin(Uri uri) {
    if (!uri.hasScheme || uri.scheme.toLowerCase() != 'https') {
      throw ArgumentError('The Supabase project URL must use HTTPS.');
    }
    if (!uri.hasAuthority || uri.host.isEmpty) {
      throw ArgumentError('The Supabase project URL must include a host.');
    }
    if (uri.userInfo.isNotEmpty || uri.authority.contains('@')) {
      throw ArgumentError(
        'The Supabase project URL cannot contain credentials.',
      );
    }
    if (uri.hasQuery || uri.hasFragment) {
      throw ArgumentError(
        'The Supabase project URL cannot contain query or fragment data.',
      );
    }
    if (uri.path.isNotEmpty && uri.path != '/') {
      throw ArgumentError(
        'The Supabase project URL must be an origin without a path.',
      );
    }

    return Uri(
      scheme: 'https',
      host: uri.host.toLowerCase(),
      port: uri.hasPort && uri.port != 443 ? uri.port : null,
    );
  }

  static String _validatePublishableKey(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed != value) {
      throw ArgumentError('A non-empty Supabase publishable key is required.');
    }

    final normalized = trimmed.toLowerCase();
    final isModernPublishable =
        normalized.startsWith('sb_publishable_') &&
        normalized.length > 'sb_publishable_'.length;
    final isLegacyAnon = _legacyJwtRole(trimmed) == 'anon';
    if (!isModernPublishable && !isLegacyAnon) {
      throw ArgumentError('Only a Supabase publishable key is accepted.');
    }

    return trimmed;
  }

  static String? _legacyJwtRole(String value) {
    final parts = value.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is! Map<String, dynamic>) {
        return null;
      }
      final role = payload['role'];
      return role is String ? role : null;
    } on FormatException {
      return null;
    }
  }
}

final supabaseConfigProvider = Provider<SupabaseConfig>(
  (ref) => SupabaseConfig.fromEnvironment(),
);
