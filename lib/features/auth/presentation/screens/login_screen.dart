import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/app_wordmark.dart';
import '../../domain/student_identity_provider.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSelectingStagingIdentity = false;
  Object? _stagingIdentityError;

  Future<void> _selectStagingIdentity(String studentCode) async {
    setState(() {
      _isSelectingStagingIdentity = true;
      _stagingIdentityError = null;
    });
    try {
      await ref.read(studentIdentityProvider).select(studentCode);
      if (!mounted) return;
      await ref.read(authControllerProvider.notifier).restoreSession();
    } on Object catch (error) {
      if (mounted) setState(() => _stagingIdentityError = error);
    } finally {
      if (mounted) setState(() => _isSelectingStagingIdentity = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final auth = ref.watch(authControllerProvider);
    final colors = Theme.of(context).colorScheme;
    final usesSampleIdentity = config.isStaging || config.enableDevFixtures;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.8),
              Theme.of(context).scaffoldBackgroundColor,
              colors.tertiaryContainer.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.hasBoundedHeight && constraints.maxHeight > 48
                      ? constraints.maxHeight - 48
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1020),
                    child: Flex(
                      direction: constraints.maxWidth >= 780
                          ? Axis.horizontal
                          : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (constraints.maxWidth >= 780)
                          const Expanded(
                            flex: 5,
                            child: _WelcomePanel(isWide: true),
                          )
                        else
                          const _WelcomePanel(isWide: false),
                        SizedBox(
                          width: constraints.maxWidth >= 780 ? 40 : 0,
                          height: constraints.maxWidth >= 780 ? 0 : 28,
                        ),
                        if (constraints.maxWidth >= 780)
                          Expanded(
                            flex: 4,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: usesSampleIdentity
                                    ? _StagingIdentitySelector(
                                        identities: ref
                                            .watch(studentIdentityProvider)
                                            .availableIdentities,
                                        error:
                                            _stagingIdentityError ?? auth.error,
                                        isSelecting:
                                            _isSelectingStagingIdentity,
                                        onSelect: _selectStagingIdentity,
                                      )
                                    : const _AuthenticationBlocker(),
                              ),
                            ),
                          )
                        else
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: usesSampleIdentity
                                  ? _StagingIdentitySelector(
                                      identities: ref
                                          .watch(studentIdentityProvider)
                                          .availableIdentities,
                                      error:
                                          _stagingIdentityError ?? auth.error,
                                      isSelecting: _isSelectingStagingIdentity,
                                      onSelect: _selectStagingIdentity,
                                    )
                                  : const _AuthenticationBlocker(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: isWide ? 20 : 0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        const AppWordmark(),
        SizedBox(height: isWide ? 32 : 20),
        Text(
          'Học tập chủ động,\nmọi lúc và mọi nơi.',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style:
              (isWide
                      ? Theme.of(context).textTheme.displaySmall
                      : Theme.of(context).textTheme.headlineMedium)
                  ?.copyWith(
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
        ),
        const SizedBox(height: 18),
        Text(
          'Theo dõi khóa học, bài tập và tiến độ trong một không gian học tập thống nhất.',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
        ),
      ],
    ),
  );
}

class _AuthenticationBlocker extends StatelessWidget {
  const _AuthenticationBlocker();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.schedule_rounded,
                color: colors.onSecondaryContainer,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Dịch vụ đăng nhập đang được chuẩn bị',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Bạn chưa thể đăng nhập vào lúc này. Chúng tôi đang hoàn thiện kết nối '
          'an toàn cho ứng dụng; vui lòng quay lại sau.',
          style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, size: 20, color: colors.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Trong thời gian này, bạn vẫn có thể học tập trên cổng DLU LMS chính thức.',
                style: TextStyle(height: 1.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StagingIdentitySelector extends StatelessWidget {
  const _StagingIdentitySelector({
    required this.identities,
    required this.error,
    required this.isSelecting,
    required this.onSelect,
  });

  final List<StudentIdentity> identities;
  final Object? error;
  final bool isSelecting;
  final Future<void> Function(String studentCode) onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.visibility_outlined,
                color: colors.onSecondaryContainer,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Dữ liệu mô phỏng phục vụ phát triển',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          error == null
              ? 'Chọn hồ sơ mẫu. Đây không phải tài khoản DLU.'
              : userMessageFor(error!),
          style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 20),
        for (final identity in identities) ...[
          FilledButton.tonalIcon(
            onPressed: isSelecting
                ? null
                : () => onSelect(identity.studentCode),
            icon: isSelecting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Icon(Icons.school_outlined),
            label: Text(identity.label),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 20, color: colors.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Môi trường này không dùng tài khoản hoặc mật khẩu DLU.',
                style: TextStyle(height: 1.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
