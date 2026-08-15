class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.idNumber,
    this.roleLabel,
    this.faculty,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? idNumber;
  final String? roleLabel;
  final String? faculty;
}
