import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/failure_message.dart';
import 'official_lms_launcher.dart';

/// No fabricated activity IDs: until an approved mapping exists, opens LMS home.
class OfficialLmsButton extends ConsumerStatefulWidget {
  const OfficialLmsButton({required this.label, super.key});
  final String label;
  @override
  ConsumerState<OfficialLmsButton> createState() => _OfficialLmsButtonState();
}

class _OfficialLmsButtonState extends ConsumerState<OfficialLmsButton> {
  bool _opening = false;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _opening
        ? null
        : () async {
            setState(() => _opening = true);
            try {
              await ref.read(officialLmsLauncherProvider).openHome();
            } on Object catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(userMessageFor(error))));
              }
            } finally {
              if (mounted) setState(() => _opening = false);
            }
          },
    icon: const Icon(Icons.open_in_new_rounded, size: 18),
    label: Text(widget.label, textAlign: TextAlign.center),
  );
}
