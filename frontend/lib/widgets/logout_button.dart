import 'package:flutter/material.dart';

/// Signs out by returning to the sign-in screen (which clears the session behind it).
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('logout'),
    tooltip: 'Đăng xuất',
    icon: const Icon(Icons.logout),
    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
  );
}
