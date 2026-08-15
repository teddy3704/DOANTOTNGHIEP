import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/app_wordmark.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final auth = ref.watch(authControllerProvider);
    final colors = Theme.of(context).colorScheme;

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
                        Expanded(
                          flex: constraints.maxWidth >= 780 ? 5 : 0,
                          child: _WelcomePanel(
                            isWide: constraints.maxWidth >= 780,
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth >= 780 ? 40 : 0,
                          height: constraints.maxWidth >= 780 ? 0 : 28,
                        ),
                        Expanded(
                          flex: constraints.maxWidth >= 780 ? 4 : 0,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: config.enableDevFixtures
                                  ? Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Đăng nhập',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Sử dụng tài khoản học tập của bạn để tiếp tục.',
                                            style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              height: 1.45,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          TextFormField(
                                            controller: _usernameController,
                                            enabled: !auth.isSubmitting,
                                            textInputAction:
                                                TextInputAction.next,
                                            autofillHints: const [
                                              AutofillHints.username,
                                            ],
                                            decoration: const InputDecoration(
                                              labelText: 'Tên đăng nhập',
                                              prefixIcon: Icon(
                                                Icons.person_outline_rounded,
                                              ),
                                            ),
                                            validator: (value) =>
                                                value == null ||
                                                    value.trim().isEmpty
                                                ? 'Vui lòng nhập tên đăng nhập.'
                                                : null,
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: _passwordController,
                                            enabled: !auth.isSubmitting,
                                            obscureText: _obscurePassword,
                                            textInputAction:
                                                TextInputAction.done,
                                            autofillHints: const [
                                              AutofillHints.password,
                                            ],
                                            onFieldSubmitted: (_) => _submit(),
                                            decoration: InputDecoration(
                                              labelText: 'Mật khẩu',
                                              prefixIcon: const Icon(
                                                Icons.lock_outline_rounded,
                                              ),
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(
                                                  () => _obscurePassword =
                                                      !_obscurePassword,
                                                ),
                                                tooltip: _obscurePassword
                                                    ? 'Hiện mật khẩu'
                                                    : 'Ẩn mật khẩu',
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                            .visibility_outlined
                                                      : Icons
                                                            .visibility_off_outlined,
                                                ),
                                              ),
                                            ),
                                            validator: (value) =>
                                                value == null || value.isEmpty
                                                ? 'Vui lòng nhập mật khẩu.'
                                                : null,
                                          ),
                                          if (auth.error != null) ...[
                                            const SizedBox(height: 16),
                                            _InlineMessage(
                                              message: userMessageFor(
                                                auth.error!,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 20),
                                          FilledButton.icon(
                                            onPressed: auth.isSubmitting
                                                ? null
                                                : _submit,
                                            icon: auth.isSubmitting
                                                ? const SizedBox.square(
                                                    dimension: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.4,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.login_rounded,
                                                  ),
                                            label: Text(
                                              auth.isSubmitting
                                                  ? 'Đang xác thực…'
                                                  : 'Tiếp tục',
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.shield_outlined,
                                                size: 18,
                                                color: colors.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Ứng dụng không lưu mật khẩu của bạn.',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  : const _AuthenticationBlocker(),
                            ),
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
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        const AppWordmark(),
        const SizedBox(height: 32),
        Text(
          'Học tập chủ động,\nmọi lúc và mọi nơi.',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
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

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colors.onErrorContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
