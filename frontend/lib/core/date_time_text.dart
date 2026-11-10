String formatDeadline(DateTime? date) {
  if (date == null) return 'Không có hạn';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

/// Relative copy is presentation only; task completion still comes from the API.
String relativeDeadline(DateTime? date, {DateTime? now}) {
  if (date == null) return 'Không có hạn';
  final current = now ?? DateTime.now();
  final remaining = date.difference(current);
  if (remaining.isNegative) {
    final elapsed = current.difference(date);
    if (elapsed.inDays >= 1) return 'Quá hạn ${elapsed.inDays} ngày';
    if (elapsed.inHours >= 1) return 'Quá hạn ${elapsed.inHours} giờ';
    return 'Quá hạn dưới 1 giờ';
  }
  final localDate = date.toLocal(), localNow = current.toLocal();
  final days = DateTime.utc(localDate.year, localDate.month, localDate.day)
      .difference(DateTime.utc(localNow.year, localNow.month, localNow.day))
      .inDays;
  if (remaining < const Duration(hours: 1)) {
    return days == 1 ? 'Ngày mai' : 'Hôm nay';
  }
  if (remaining < const Duration(hours: 24)) {
    final hours = (remaining.inSeconds / 3600).ceil();
    return 'Còn $hours giờ';
  }
  if (days == 1) return 'Ngày mai';
  return 'Còn ${remaining.inDays} ngày';
}

/// Availability of an activity, not an individual student's submission status.
String? activityDeadlineState(
  DateTime? deadline, {
  required bool quiz,
  DateTime? now,
}) {
  if (deadline == null) return 'Không có hạn';
  final remaining = deadline.difference(now ?? DateTime.now());
  if (remaining.isNegative) return quiz ? 'Đã đóng' : 'Đã hết hạn';
  if (remaining <= const Duration(hours: 48)) return 'Sắp đến hạn';
  return null;
}
