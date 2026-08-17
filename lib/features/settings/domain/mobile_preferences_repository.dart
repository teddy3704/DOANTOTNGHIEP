import '../../../core/errors/app_failure.dart';
import 'mobile_preferences.dart';

abstract interface class MobilePreferencesRepository {
  Future<MobilePreferences?> getForCurrentUser();

  Future<MobilePreferences> saveThemeMode(PreferredThemeMode themeMode);
}

final class UnconfiguredMobilePreferencesRepository
    implements MobilePreferencesRepository {
  const UnconfiguredMobilePreferencesRepository();

  @override
  Future<MobilePreferences?> getForCurrentUser() {
    throw const ConfigurationFailure(
      'Dịch vụ dữ liệu ứng dụng chưa được kết nối.',
      code: 'SUPABASE_PROJECT_CONNECTION_REQUIRED',
    );
  }

  @override
  Future<MobilePreferences> saveThemeMode(PreferredThemeMode themeMode) {
    throw const ConfigurationFailure(
      'Dịch vụ dữ liệu ứng dụng chưa được kết nối.',
      code: 'SUPABASE_PROJECT_CONNECTION_REQUIRED',
    );
  }
}
