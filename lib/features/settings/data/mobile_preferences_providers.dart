import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/supabase_identity_session.dart';
import '../../../core/network/supabase_client_factory.dart';
import '../domain/mobile_preferences_repository.dart';
import 'mobile_preferences_remote_data_source.dart';
import 'supabase_mobile_preferences_repository.dart';

final mobilePreferencesSupabaseGatewayProvider =
    Provider<MobilePreferencesSupabaseGateway>(
      (ref) => SupabaseClientMobilePreferencesGateway(
        ref.watch(supabaseClientProvider),
      ),
    );

final mobilePreferencesRemoteDataSourceProvider =
    Provider<MobilePreferencesRemoteDataSource>(
      (ref) => SupabaseMobilePreferencesRemoteDataSource(
        gateway: ref.watch(mobilePreferencesSupabaseGatewayProvider),
        identitySession: ref.watch(supabaseIdentitySessionProvider),
      ),
    );

final mobilePreferencesRepositoryProvider =
    Provider<MobilePreferencesRepository>(
      (ref) => SupabaseMobilePreferencesRepository(
        ref.watch(mobilePreferencesRemoteDataSourceProvider),
      ),
    );
