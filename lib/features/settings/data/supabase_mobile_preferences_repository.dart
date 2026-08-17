import '../domain/mobile_preferences.dart';
import '../domain/mobile_preferences_repository.dart';
import 'mobile_preferences_remote_data_source.dart';

final class SupabaseMobilePreferencesRepository
    implements MobilePreferencesRepository {
  const SupabaseMobilePreferencesRepository(this._remoteDataSource);

  final MobilePreferencesRemoteDataSource _remoteDataSource;

  @override
  Future<MobilePreferences?> getForCurrentUser() async {
    final dto = await _remoteDataSource.fetchForCurrentUser();
    return dto?.toDomain();
  }

  @override
  Future<MobilePreferences> saveThemeMode(PreferredThemeMode themeMode) async {
    final dto = await _remoteDataSource.saveThemeMode(themeMode);
    return dto.toDomain();
  }
}
