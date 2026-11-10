class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// Machine-readable code from the server body, e.g. PORTAL_NOT_LINKED.
  final String? code;
  const ApiException(this.message, {this.statusCode, this.code});

  factory ApiException.http(int status, {String? code}) => ApiException(
    switch (code) {
      'PORTAL_NOT_LINKED' => 'Tài khoản chưa liên kết với Portal đào tạo.',
      'PORTAL_DISABLED' => 'Chưa kết nối Portal đào tạo.',
      'PORTAL_UNAVAILABLE' =>
        'Portal đào tạo đang không phản hồi. Vui lòng thử lại sau.',
      _ => switch (status) {
        401 => 'Phiên đăng nhập đã hết hạn. Vui lòng quay lại đăng nhập.',
        403 => 'Tài khoản không có quyền truy cập nội dung này.',
        404 => 'Chưa tìm thấy dữ liệu hoặc chức năng trên máy chủ.',
        _ => 'Máy chủ chưa xử lý được yêu cầu. Vui lòng thử lại.',
      },
    },
    statusCode: status,
    code: code,
  );

  bool get portalNotLinked => code == 'PORTAL_NOT_LINKED';
  bool get portalDisabled => code == 'PORTAL_DISABLED';

  @override
  String toString() => statusCode == null ? message : '$message ($statusCode)';
}

String apiErrorMessage(Object error) => error is ApiException
    ? error.message
    : 'Không thể xử lý dữ liệu. Vui lòng thử lại.';
