import 'package:flutter_test/flutter_test.dart';
import 'package:lms_mobile_app/core/relative_days.dart';
import 'package:lms_mobile_app/models/teacher_monitoring.dart';

void main() {
  test('past, today and future are shown honestly', () {
    expect(daysAgoLabel(3), '3 ngày trước');
    expect(daysAgoLabel(1), 'hôm qua');
    expect(daysAgoLabel(0), 'hôm nay');
    expect(daysAgoLabel(-6), 'sau hôm nay 6 ngày');
    expect(daysAgoTitle(-1), 'Sau hôm nay 1 ngày');
    expect(daysAgoTitle(0), 'Hôm nay');
  });

  test('teacher monitoring label never prints a negative day count', () {
    String label(int? d) => MonitoredStudent.fromJson({
      'userid': 1,
      'days_since_last_activity': d,
    }).activityLabel;
    expect(label(-6), 'Hoạt động gần nhất: sau hôm nay 6 ngày');
    expect(label(0), 'Hoạt động gần nhất: hôm nay');
    expect(label(9), 'Hoạt động gần nhất: 9 ngày trước');
    expect(label(-6), isNot(contains('-')));
  });
}
