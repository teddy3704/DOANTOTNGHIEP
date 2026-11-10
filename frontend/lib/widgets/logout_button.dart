import 'package:flutter/material.dart';

import '../core/app_settings.dart';

/// Signs out by returning to the sign-in screen (which clears the session behind it).
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('logout'),
    tooltip: 'Đăng xuất',
    icon: const Icon(Icons.logout),
    onPressed: () => signOut(context),
  );
}

void signOut(BuildContext context) =>
    Navigator.of(context).popUntil((r) => r.isFirst);

enum _AccountAction { system, light, dark, logout }

/// POLISH-2: account menu on both home screens — light / dark / follow the phone, and sign out.
/// One icon instead of two keeps the app bar readable at 320 dp and large text.
class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: AppSettings.themeMode,
    builder: (context, mode, _) => PopupMenuButton<_AccountAction>(
      key: const Key('account-menu'),
      tooltip: 'Tài khoản và giao diện',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (a) => switch (a) {
        _AccountAction.system => AppSettings.setThemeMode(ThemeMode.system),
        _AccountAction.light => AppSettings.setThemeMode(ThemeMode.light),
        _AccountAction.dark => AppSettings.setThemeMode(ThemeMode.dark),
        _AccountAction.logout => signOut(context),
      },
      itemBuilder: (_) => [
        const PopupMenuItem<_AccountAction>(
          enabled: false,
          child: Text('Giao diện'),
        ),
        for (final (action, label, value) in const [
          (_AccountAction.system, 'Theo máy', ThemeMode.system),
          (_AccountAction.light, 'Sáng', ThemeMode.light),
          (_AccountAction.dark, 'Tối', ThemeMode.dark),
        ])
          CheckedPopupMenuItem<_AccountAction>(
            key: Key('theme-${value.name}'),
            value: action,
            checked: mode == value,
            child: Text(label),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<_AccountAction>(
          key: Key('logout'),
          value: _AccountAction.logout,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Đăng xuất'),
          ),
        ),
      ],
    ),
  );
}
