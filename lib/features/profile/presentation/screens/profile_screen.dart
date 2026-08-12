import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/app_user.dart';
import '../../domain/user_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user.when(
      loading: () => const LoadingState(label: 'Đang tải hồ sơ…'),
      error: (error, _) => ErrorState(
        message: userMessageFor(error),
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
      data: (profile) => _ProfileContent(profile: profile),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Thông tin cá nhân',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Flex(
                      direction: constraints.maxWidth >= 520
                          ? Axis.horizontal
                          : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
                          child: Text(
                            _initials(profile.displayName),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth >= 520 ? 22 : 0,
                          height: constraints.maxWidth >= 520 ? 0 : 18,
                        ),
                        Expanded(
                          flex: constraints.maxWidth >= 520 ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: constraints.maxWidth >= 520
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.center,
                            children: [
                              Text(
                                profile.displayName,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                profile.roleLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.primary),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                profile.faculty,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.alternate_email_rounded,
                      title: 'Email',
                      value: profile.email,
                    ),
                    const Divider(),
                    _InfoTile(
                      icon: Icons.language_rounded,
                      title: 'LMS',
                      value: config.moodleBaseUri.host,
                    ),
                    const Divider(),
                    const _InfoTile(
                      icon: Icons.shield_outlined,
                      title: 'Bảo mật',
                      value:
                          'Token được lưu bằng secure storage khi tích hợp thật',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );
}
