import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// V2-N11 "Đang ngoại tuyến · dữ liệu lúc 21:30" while cached data is shown.
class OfflineBanner extends StatelessWidget {
  final ApiService api;
  const OfflineBanner({super.key, required this.api});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<DateTime?>(
    valueListenable: api.offlineSince,
    builder: (context, at, _) {
      if (at == null) return const SizedBox.shrink();
      final scheme = Theme.of(context).colorScheme;
      String two(int v) => v.toString().padLeft(2, '0');
      return Material(
        key: const Key('offline-banner'),
        color: scheme.tertiaryContainer,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 18,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang ngoại tuyến · dữ liệu lúc ${two(at.hour)}:${two(at.minute)} '
                    '${two(at.day)}/${two(at.month)}',
                    style: TextStyle(color: scheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
