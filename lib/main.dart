import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() {
  final config = AppConfig.fromEnvironment();

  runDluLmsApp(
    overrides: <Override>[appConfigProvider.overrideWithValue(config)],
  );
}
