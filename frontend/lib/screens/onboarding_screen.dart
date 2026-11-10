import 'package:flutter/material.dart';

import '../core/app_settings.dart';

class _Step {
  final IconData icon;
  final String title, text;
  const _Step(this.icon, this.title, this.text);
}

const _steps = [
  _Step(
    Icons.calculate_outlined,
    'Mô phỏng điểm',
    'Biết cần bao nhiêu điểm ở các bài còn lại để qua môn hoặc đạt mục tiêu.',
  ),
  _Step(
    Icons.event_note_outlined,
    'Kế hoạch tuần',
    'Biến danh sách hạn nộp thành lịch học từng ngày vừa với thời gian của bạn.',
  ),
  _Step(
    Icons.style_outlined,
    'Ôn thẻ thông minh',
    'Ứng dụng tự xếp lịch thẻ nào cần ôn hôm nay để nhớ lâu hơn.',
  ),
];

/// V2-N18 three-step introduction shown once, after the first role choice.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppSettings.markOnboardingSeen();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('onboarding-skip'),
                onPressed: _finish,
                child: const Text('Bỏ qua'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final s in _steps)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            s.icon,
                            size: 72,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            s.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.text,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  Container(
                    width: i == _page ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding-next'),
                  onPressed: last
                      ? _finish
                      : () => _pages.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                  child: Text(last ? 'Bắt đầu' : 'Tiếp'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
