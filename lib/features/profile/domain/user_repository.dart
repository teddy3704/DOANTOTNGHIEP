import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'app_user.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

abstract interface class UserRepository {
  Future<AppUser> getCurrentUser();
}

class UnconfiguredUserRepository implements UserRepository {
  const UnconfiguredUserRepository();

  @override
  Future<AppUser> getCurrentUser() {
    throw const ConfigurationFailure(
      'API thông tin người dùng DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_NOT_ENABLED',
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => const UnconfiguredUserRepository(),
);

final currentUserProvider = FutureProvider.autoDispose<AppUser>((ref) {
  ref.watch(authControllerProvider.select((state) => state.session?.userId));
  return ref.watch(userRepositoryProvider).getCurrentUser();
});
