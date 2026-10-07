import 'package:dlu_lms_mobile/core/parsing/api_timestamp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explicit offsets preserve the same instant, including leap dates', () {
    expect(
      tryParseApiTimestamp('2028-02-29T17:22:00+07:00'),
      DateTime.utc(2028, 2, 29, 10, 22),
    );
    expect(
      tryParseApiTimestamp('2028-02-29T10:22:00.123Z'),
      DateTime.utc(2028, 2, 29, 10, 22, 0, 123),
    );
  });

  test(
    'invalid calendar, missing timezone and out-of-range time fail closed',
    () {
      for (final value in <Object?>[
        null,
        0,
        '',
        '2026-02-29T12:00:00Z',
        '2026-04-31T12:00:00Z',
        '2026-13-01T12:00:00Z',
        '2026-10-07T24:00:00Z',
        '2026-10-07T12:60:00Z',
        '2026-10-07T12:00:60Z',
        '2026-10-07T12:00:00',
        '2026-10-07',
        '2026-10-07T12:00:00+24:00',
        '2026-10-07T12:00:00+07:60',
      ]) {
        expect(tryParseApiTimestamp(value), isNull, reason: '$value');
      }
    },
  );
}
