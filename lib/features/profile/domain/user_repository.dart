import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'app_user.dart';

abstract interface class UserRepository {
  Future<AppUser> getCurrentUser();
}

class UnconfiguredUserRepository implements UserRepository {
  const UnconfiguredUserRepository();

  @override
  Future<AppUser> getCurrentUser() {
    throw const ConfigurationFailure(
      'API thông tin người dùng DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_STATUS_REQUIRED',
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => const UnconfiguredUserRepository(),
);

final currentUserProvider = FutureProvider<AppUser>(
  (ref) => ref.watch(userRepositoryProvider).getCurrentUser(),
);
