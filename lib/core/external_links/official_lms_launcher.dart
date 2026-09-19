import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../config/app_config.dart';
import '../errors/app_failure.dart';

typedef ExternalUrlLaunch = Future<bool> Function(Uri uri);

/// Opens only the configured official LMS origin.
///
/// Activity deep links are intentionally not synthesized. Until a specific DLU
/// activity URL is verified, the safe fallback is the configured LMS home page.
class OfficialLmsLauncher {
  OfficialLmsLauncher({required Uri lmsBaseUri, ExternalUrlLaunch? launch})
    : _lmsBaseUri = _normalizeOfficialOrigin(lmsBaseUri),
      _launch = launch ?? _launchExternal;

  final Uri _lmsBaseUri;
  final ExternalUrlLaunch _launch;

  Future<void> openHome() async {
    final launched = await _launch(_lmsBaseUri);
    if (!launched) {
      throw const MoodleApiFailure(
        'Không thể mở DLU LMS trên thiết bị này.',
        code: 'OFFICIAL_LMS_OPEN_UNAVAILABLE',
      );
    }
  }

  static Future<bool> _launchExternal(Uri uri) => url_launcher.launchUrl(
    uri,
    mode: url_launcher.LaunchMode.externalApplication,
  );

  static Uri _normalizeOfficialOrigin(Uri value) {
    if (value.scheme.toLowerCase() != 'https' ||
        value.host.toLowerCase() != 'lms.dlu.edu.vn' ||
        value.userInfo.isNotEmpty ||
        value.hasQuery ||
        value.hasFragment ||
        (value.hasPort && value.port != 443) ||
        (value.path.isNotEmpty && value.path != '/')) {
      throw ArgumentError.value(
        value,
        'lmsBaseUri',
        'Only the configured official DLU LMS origin may be opened.',
      );
    }
    return Uri(scheme: 'https', host: 'lms.dlu.edu.vn');
  }
}

final officialLmsLauncherProvider = Provider<OfficialLmsLauncher>(
  (ref) => OfficialLmsLauncher(
    lmsBaseUri: ref.watch(appConfigProvider).moodleBaseUri,
  ),
);
