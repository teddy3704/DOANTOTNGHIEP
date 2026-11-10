/// Days since an event as shown to people. A negative count means the
/// recorded time is after "now" (e.g. the demo database was date-shifted);
/// it is shown as such, never folded into the past.
String daysAgoLabel(int days) {
  if (days < 0) return 'sau hôm nay ${-days} ngày';
  if (days == 0) return 'hôm nay';
  if (days == 1) return 'hôm qua';
  return '$days ngày trước';
}

/// Sentence-case variant for labels that stand alone.
String daysAgoTitle(int days) {
  final s = daysAgoLabel(days);
  return s[0].toUpperCase() + s.substring(1);
}
