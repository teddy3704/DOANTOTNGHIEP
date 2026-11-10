import 'package:flutter/material.dart';

import 'core/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'core/vietnamese_localizations.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  runApp(const LMSApp());
}

class LMSApp extends StatelessWidget {
  const LMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'Hỗ trợ học tập LMS',
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN')],
        localizationsDelegates: const [
          VietnameseMaterialDelegate(),
          VietnameseWidgetsDelegate(),
          VietnameseCupertinoDelegate(),
        ],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: const LoginScreen(),
      ),
    );
  }
}
