import '../core/theme/app_colors.dart';
import '../core/app_settings.dart';
import 'onboarding_screen.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/api_exception.dart';
import 'student/student_main_screen.dart';
import 'teacher/teacher_main_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final ApiService? apiService;
  const RoleSelectionScreen({super.key, this.apiService});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  bool _isSigningIn = false;
  String? _error;

  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  Future<void> _openRole(String role) async {
    if (_isSigningIn) return;
    setState(() {
      _isSigningIn = true;
      _error = null;
    });
    try {
      await _api.demoLogin(role);
      if (!mounted) return;
      if (AppSettings.onboardingEnabled && !AppSettings.onboardingSeen) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        if (!mounted) return;
      }
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'STUDENT'
              ? StudentMainScreen(apiService: _api)
              : TeacherMainScreen(apiService: _api),
        ),
      );
      _api.signOut();
    } catch (error) {
      if (mounted) setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_api.localDevelopment) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hỗ trợ học tập LMS'),
          actions: const [ThemeModeMenu()],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Đăng nhập LMS chưa được cấu hình.\n'
              'Chọn vai trò chỉ khả dụng trong bản thử nghiệm local được bật rõ ràng.\n'
              'Không có dữ liệu giả thay thế kết nối máy chủ.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (Navigator.of(context).canPop())
              const Positioned(top: 4, left: 4, child: BackButton()),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // Header section
                  Icon(
                    Icons.school_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  if (_isSigningIn) const LinearProgressIndicator(),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  Text(
                    'Hỗ trợ học tập LMS',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khóa học, việc cần làm và tiến độ học tập',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Role Buttons / Cards
                  Text(
                    'Chọn vai trò truy cập',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Student Role Button
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isSigningIn ? null : () => _openRole('STUDENT'),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.tint(Colors.blue),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF1E88E5),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sinh viên',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Xem nội dung, hạn nộp, điểm và chuyên cần',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: context.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Teacher Role Button
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isSigningIn ? null : () => _openRole('TEACHER'),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.tint(Colors.teal),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Colors.teal,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Giảng viên',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Theo dõi khóa học và hỗ trợ sinh viên',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: context.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Chế độ thử nghiệm footer note
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.tint(Colors.amber),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.tintBorder(Colors.amber),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.developer_mode,
                            size: 16,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Thử nghiệm local • Không phải đăng nhập DLU',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(top: 4, right: 4, child: const ThemeModeMenu()),
          ],
        ),
      ),
    );
  }
}

/// V2-N18 Sáng / Tối / Theo hệ thống; saved on the device.
class ThemeModeMenu extends StatelessWidget {
  const ThemeModeMenu({super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton<ThemeMode>(
    key: const Key('theme-menu'),
    tooltip: 'Giao diện sáng/tối',
    icon: const Icon(Icons.brightness_6_outlined),
    initialValue: AppSettings.themeMode.value,
    onSelected: AppSettings.setThemeMode,
    itemBuilder: (_) => const [
      PopupMenuItem(value: ThemeMode.system, child: Text('Theo hệ thống')),
      PopupMenuItem(value: ThemeMode.light, child: Text('Sáng')),
      PopupMenuItem(value: ThemeMode.dark, child: Text('Tối')),
    ],
  );
}
