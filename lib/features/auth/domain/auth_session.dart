enum DluRole { student, teacher }

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.displayName,
    this.role = DluRole.student,
  });

  final String userId;
  final String displayName;
  final DluRole role;
}
