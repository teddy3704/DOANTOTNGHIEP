/// Parse a timestamp only when calendar/time fields and an explicit offset are
/// valid. DateTime.tryParse alone normalizes impossible dates (e.g. 30 February)
/// and accepts device-local timestamps, which corrupt scheduling semantics.
DateTime? tryParseApiTimestamp(Object? value) {
  if (value is! String) return null;
  final parts = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-](\d{2}):(\d{2}))$',
  ).firstMatch(value);
  if (parts == null) return null;
  final year = int.parse(parts[1]!);
  final month = int.parse(parts[2]!);
  final day = int.parse(parts[3]!);
  final calendar = DateTime.utc(year, month, day);
  if (calendar.year != year ||
      calendar.month != month ||
      calendar.day != day ||
      int.parse(parts[4]!) >= 24 ||
      int.parse(parts[5]!) >= 60 ||
      int.parse(parts[6]!) >= 60 ||
      (parts[7] != null && int.parse(parts[7]!) >= 24) ||
      (parts[8] != null && int.parse(parts[8]!) >= 60)) {
    return null;
  }
  return DateTime.tryParse(value);
}
