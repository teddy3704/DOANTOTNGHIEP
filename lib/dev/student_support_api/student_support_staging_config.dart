import '../../core/errors/app_failure.dart';

/// Non-secret configuration for the explicitly selected development/staging API.
///
/// This class is intentionally kept out of the production bootstrap. The student
/// code is a synthetic development identity accepted only by the staging API; it
/// is not an LMS password, token, or production authentication mechanism.
class StudentSupportStagingConfig {
  StudentSupportStagingConfig({
    required Uri baseUri,
    required String studentCode,
  }) : baseUri = _normalizeOrigin(baseUri),
       studentCode = _normalizeStudentCode(studentCode);

  factory StudentSupportStagingConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'STUDENT_SUPPORT_API_BASE_URL',
      defaultValue: 'https://dlu-lms-student-support-staging.onrender.com',
    );
    const studentCode = String.fromEnvironment(
      'STUDENT_SUPPORT_STUDENT_CODE',
      defaultValue: 'SV001',
    );
    return StudentSupportStagingConfig(
      baseUri: Uri.parse(baseUrl),
      studentCode: studentCode,
    );
  }

  final Uri baseUri;
  final String studentCode;

  static Uri _normalizeOrigin(Uri uri) {
    if (!uri.hasScheme || uri.scheme.toLowerCase() != 'https') {
      throw const ConfigurationFailure(
        'Cấu hình môi trường học tập thử nghiệm phải dùng HTTPS.',
        code: 'STAGING_API_HTTPS_REQUIRED',
      );
    }
    if (!uri.hasAuthority || uri.host.isEmpty) {
      throw const ConfigurationFailure(
        'Cấu hình máy chủ học tập thử nghiệm không hợp lệ.',
        code: 'STAGING_API_ORIGIN_INVALID',
      );
    }
    if (uri.userInfo.isNotEmpty || uri.authority.contains('@')) {
      throw const ConfigurationFailure(
        'Cấu hình máy chủ học tập thử nghiệm không hợp lệ.',
        code: 'STAGING_API_ORIGIN_INVALID',
      );
    }
    if (uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const ConfigurationFailure(
        'Cấu hình máy chủ học tập thử nghiệm không hợp lệ.',
        code: 'STAGING_API_ORIGIN_INVALID',
      );
    }
    return Uri(
      scheme: 'https',
      host: uri.host.toLowerCase(),
      port: uri.hasPort && uri.port != 443 ? uri.port : null,
    );
  }

  static String _normalizeStudentCode(String value) {
    final normalized = value.trim().toUpperCase();
    if (!RegExp(r'^SV[0-9]{3}$').hasMatch(normalized)) {
      throw const ConfigurationFailure(
        'Mã người học của môi trường thử nghiệm không hợp lệ.',
        code: 'STAGING_STUDENT_CODE_INVALID',
      );
    }
    return normalized;
  }
}
