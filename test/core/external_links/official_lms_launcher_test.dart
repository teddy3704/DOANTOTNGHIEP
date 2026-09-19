import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/core/external_links/official_lms_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects credentials, alternate ports and unverified destinations', () {
    for (final value in [
      'https://lms.dlu.edu.vn:8080',
      'https://user@lms.dlu.edu.vn',
      'https://lms.dlu.edu.vn/?token=example',
      'https://lms.dlu.edu.vn.evil.test',
      'https://lms.dlu.edu.vn/mod/assign/view.php?id=123',
    ]) {
      expect(
        () => OfficialLmsLauncher(lmsBaseUri: Uri.parse(value)),
        throwsArgumentError,
      );
    }
  });
  test('launches only the canonical official LMS origin', () async {
    Uri? opened;
    final launcher = OfficialLmsLauncher(
      lmsBaseUri: Uri.parse('https://lms.dlu.edu.vn/'),
      launch: (uri) async {
        opened = uri;
        return true;
      },
    );

    await launcher.openHome();

    expect(opened, Uri.parse('https://lms.dlu.edu.vn'));
  });

  test('rejects arbitrary and non-HTTPS launch origins', () {
    expect(
      () => OfficialLmsLauncher(lmsBaseUri: Uri.parse('http://lms.dlu.edu.vn')),
      throwsArgumentError,
    );
    expect(
      () => OfficialLmsLauncher(
        lmsBaseUri: Uri.parse('https://untrusted.example.test'),
      ),
      throwsArgumentError,
    );
  });

  test(
    'maps an unavailable external handler to a safe application failure',
    () {
      final launcher = OfficialLmsLauncher(
        lmsBaseUri: Uri.parse('https://lms.dlu.edu.vn'),
        launch: (uri) async => false,
      );

      expectLater(launcher.openHome(), throwsA(isA<MoodleApiFailure>()));
    },
  );
}
