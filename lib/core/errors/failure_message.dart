import 'app_failure.dart';
import '../../features/reminders/domain/reminder_exception.dart';

String userMessageFor(Object error) => switch (error) {
  AuthenticationFailure() =>
    'Không thể đăng nhập. Vui lòng kiểm tra thông tin và thử lại.',
  PermissionFailure() => 'Bạn không có quyền thực hiện thao tác này.',
  TimeoutFailure() =>
    'Kết nối mất quá nhiều thời gian. Vui lòng kiểm tra mạng và thử lại.',
  NetworkFailure() => 'Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.',
  ConfigurationFailure() =>
    'Dịch vụ này hiện chưa sẵn sàng. Vui lòng thử lại sau.',
  ServerFailure() => 'Dịch vụ đang gặp sự cố. Vui lòng thử lại sau.',
  ParsingFailure() =>
    'Dữ liệu tạm thời chưa thể hiển thị. Vui lòng thử lại sau.',
  MoodleApiFailure() => 'Yêu cầu chưa thể hoàn tất. Vui lòng thử lại sau.',
  ReminderException() => error.message,
  _ => 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
};
