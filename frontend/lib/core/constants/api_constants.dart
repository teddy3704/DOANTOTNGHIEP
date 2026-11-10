import 'package:flutter/foundation.dart';

class ApiConstants {
  // No token/password belongs in dart-define: these values are bundled in APKs.
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');
  static const bool localDevelopment =
      kDebugMode && bool.fromEnvironment('LOCAL_DEVELOPMENT');
  static const String moodleBaseUrl = 'https://lms.dlu.edu.vn';

  static Uri validateBaseUrl(String value, {required bool localDevelopment}) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.path != '/api/v1') {
      throw const FormatException('API_BASE_URL phải kết thúc bằng /api/v1.');
    }
    final localHost = const {
      'localhost',
      '127.0.0.1',
      '::1',
      '10.0.2.2',
    }.contains(uri.host);
    if (uri.scheme != 'https' &&
        !(localDevelopment && uri.scheme == 'http' && localHost)) {
      throw const FormatException('API cần HTTPS; HTTP chỉ dành cho local.');
    }
    if (localDevelopment && !localHost) {
      throw const FormatException(
        'Đăng nhập thử nghiệm chỉ dùng máy chủ local.',
      );
    }
    return uri;
  }
}
