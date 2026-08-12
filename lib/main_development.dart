import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'dev/fixtures/dev_repositories.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/courses/domain/course_repository.dart';
import 'features/profile/domain/user_repository.dart';

void main() {
  runDluLmsApp(
    overrides: <Override>[
      appConfigProvider.overrideWithValue(AppConfig.development()),
      authRepositoryProvider.overrideWithValue(DevAuthRepository()),
      courseRepositoryProvider.overrideWithValue(DevCourseRepository()),
      userRepositoryProvider.overrideWithValue(DevUserRepository()),
    ],
  );
}
