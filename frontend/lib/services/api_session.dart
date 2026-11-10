/// Memory-only session. Closing the app discards the local development token.
/// Production authentication/secure persistence is intentionally not simulated.
class ApiSession {
  String? _token;
  int? _userId;
  String? _role;

  String? get token => _token;

  void accept(Map<String, dynamic> response, {required String requestedRole}) {
    final token = response['token'];
    final id = int.tryParse('${response['userId']}');
    final role = response['role'];
    if (token is! String ||
        token.trim().isEmpty ||
        token.contains(RegExp(r'\s')) ||
        id == null ||
        id <= 0 ||
        role != requestedRole.toUpperCase()) {
      clear();
      throw const FormatException('Phản hồi đăng nhập không hợp lệ.');
    }
    _token = token;
    _userId = id;
    _role = role as String;
  }

  int userIdFor(String role) {
    if (_token == null || _userId == null || _role != role) {
      throw StateError('Cần đăng nhập đúng vai trò trước khi truy cập.');
    }
    return _userId!;
  }

  void clear() {
    _token = null;
    _userId = null;
    _role = null;
  }
}
