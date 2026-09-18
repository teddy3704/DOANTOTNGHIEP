import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/theme_mode_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/widgets/content_skeleton.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/app_user.dart';
import '../../domain/user_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user.when(
      loading: () => const ContentSkeleton(rows: 4, rowHeight: 96),
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
    final colors = Theme.of(context).colorScheme;
    final themeMode = ref.watch(appThemeModeProvider);
    final config = ref.watch(appConfigProvider);
    return SingleChildScrollView(
      padding: AppLayout.pagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hồ sơ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          constraints.maxWidth >= AppLayout.compactBreakpoint;
                      final avatar = CircleAvatar(
                        radius: 46,
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                        child: Text(
                          _initials(profile.displayName),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      );
                      final identity = Column(
                        crossAxisAlignment: wide
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Text(
                            profile.displayName.trim().isEmpty
                                ? 'Người học'
                                : profile.displayName,
                            textAlign: wide ? TextAlign.left : TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (profile.roleLabel case final role?) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              role,
                              textAlign: wide
                                  ? TextAlign.left
                                  : TextAlign.center,
                              style: TextStyle(color: colors.primary),
                            ),
                          ],
                          if (profile.faculty case final faculty?) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              faculty,
                              textAlign: wide
                                  ? TextAlign.left
                                  : TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      );
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            avatar,
                            const SizedBox(width: AppSpacing.xl),
                            Expanded(child: identity),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          avatar,
                          const SizedBox(height: AppSpacing.md),
                          identity,
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (profile.email case final email?) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: _InfoTile(
                    icon: Icons.alternate_email_rounded,
                    title: 'Email',
                    value: email,
                  ),
                ),
              ],
              if (profile.idNumber case final idNumber?) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: _InfoTile(
                    icon: Icons.badge_outlined,
                    title: 'Mã sinh viên',
                    value: idNumber,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Tùy chọn ứng dụng',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.contrast_rounded, color: colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giao diện',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text('Chọn chế độ hiển thị phù hợp.'),
                          ],
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<ThemeMode>(
                          value: themeMode,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('Hệ thống'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Sáng'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Tối'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(appThemeModeProvider.notifier).state =
                                  value;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!config.isStaging) ...[
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'NH';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
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
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );
}
