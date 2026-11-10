import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/api_constants.dart';

/// Only activity paths supplied by the API are used; never derive IDs from source_id.
Uri? moodleActivityUri(String? path, int? courseModuleId) {
  if (path == null ||
      path.trim().isEmpty ||
      courseModuleId == null ||
      courseModuleId <= 0) {
    return null;
  }
  final supplied = Uri.tryParse(path.trim());
  final base = Uri.parse(ApiConstants.moodleBaseUrl);
  if (supplied == null) return null;
  final absolute = supplied.hasScheme;
  if (absolute) {
    if (supplied.scheme != base.scheme ||
        supplied.host != base.host ||
        supplied.port != base.port ||
        supplied.userInfo.isNotEmpty) {
      return null;
    }
  } else if (supplied.hasAuthority || !path.trim().startsWith('/')) {
    return null;
  }
  if (!RegExp(r'^/mod/[a-z][a-z0-9_]*/view\.php$').hasMatch(supplied.path) ||
      supplied.queryParametersAll['id']?.length != 1 ||
      supplied.queryParameters['id'] != courseModuleId.toString()) {
    return null;
  }
  return absolute ? supplied : base.resolveUri(supplied);
}

class MoodleButton extends StatelessWidget {
  final String? path;
  final int? courseModuleId;
  final String label;
  final bool compact, tonal;
  const MoodleButton({
    super.key,
    required this.path,
    required this.courseModuleId,
    this.label = 'Mở trên LMS',
    this.compact = false,
    this.tonal = false,
  });

  @override
  Widget build(BuildContext context) {
    final uri = moodleActivityUri(path, courseModuleId);
    final VoidCallback? onOpen = uri == null
        ? null
        : () async {
            try {
              final opened = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!opened) {
                throw StateError('External launch returned false');
              }
            } catch (error, stack) {
              debugPrint('Moodle launch: $error\n$stack');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể mở LMS. Vui lòng thử lại.'),
                  ),
                );
              }
            }
          };
    final style = compact
        ? TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: const Size(0, 36),
            visualDensity: VisualDensity.compact,
          )
        : null;
    const icon = Icon(Icons.open_in_new, size: 16);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tonal)
          FilledButton.tonalIcon(
            onPressed: onOpen,
            style: style,
            icon: icon,
            label: Text(label, textAlign: TextAlign.center),
          )
        else if (compact)
          TextButton.icon(
            onPressed: onOpen,
            style: style,
            icon: icon,
            label: Text(label, textAlign: TextAlign.center),
          )
        else
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: icon,
            label: Text(label, textAlign: TextAlign.center),
          ),
        if (uri == null)
          Text(
            'Chưa có liên kết LMS khả dụng',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
