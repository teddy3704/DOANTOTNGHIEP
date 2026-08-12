class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.roleLabel,
    required this.faculty,
  });

  final String id;
  final String displayName;
  final String email;
  final String roleLabel;
  final String faculty;
}
