import 'app_failure.dart';

String userMessageFor(Object error) => switch (error) {
  AuthenticationFailure() => error.message,
  PermissionFailure() =>
    'Bạn chưa được Moodle cấp quyền thực hiện thao tác này.',
  TimeoutFailure() =>
    'Kết nối mất quá nhiều thời gian. Vui lòng kiểm tra mạng và thử lại.',
  NetworkFailure() =>
    'Không thể kết nối tới hệ thống LMS. Vui lòng kiểm tra mạng.',
  ConfigurationFailure() => error.message,
  ServerFailure() => 'Hệ thống LMS đang gặp sự cố. Vui lòng thử lại sau.',
  ParsingFailure() =>
    'Ứng dụng chưa thể đọc phản hồi từ LMS. Vui lòng báo cho nhóm phát triển.',
  MoodleApiFailure() => error.message,
  _ => 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
};
