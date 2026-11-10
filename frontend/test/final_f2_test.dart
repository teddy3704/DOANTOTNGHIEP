import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/theme/app_colors.dart';
import 'package:lms_mobile_app/core/theme/app_theme.dart';
import 'package:lms_mobile_app/services/api_exception.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/widgets/chart_axis.dart';

import 'support/mock_api.dart';

void main() {
  test(
    'screens use theme colours, not fixed greys, black or very light backgrounds',
    () {
      // Fixed light backgrounds made the teacher copilot card unreadable in dark mode (found on device).
      final banned = RegExp(
        r'Colors\.grey\.shade|Colors\.black87|Color\(0xFF1E293B\)'
        r'|Color\(0xFF[EF][0-9A-F][EF][0-9A-F][EF][0-9A-F]\)',
      );
      final offenders = <String>[];
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>()) {
        final path = f.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart') || path.contains('core/theme/')) continue;
        final lines = f.readAsLinesSync();
        for (var n = 0; n < lines.length; n++) {
          if (banned.hasMatch(lines[n])) offenders.add('$path:${n + 1}');
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test('slow first Portal read waits longer than ordinary requests', () async {
    final api = ApiService(
      client: MockClient((r) async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return http.Response('{"ok":true}', 200);
      }),
      baseUrl: mockApiBaseUrl,
      localDevelopment: true,
      session: MockApiSession(),
      requestTimeout: const Duration(milliseconds: 40),
      portalTimeout: const Duration(seconds: 5),
    );
    // Ordinary endpoint: times out at requestTimeout.
    await expectLater(
      api.getStudyPlan(),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'm', contains('quá lâu')),
      ),
    );
    // Portal endpoint: the same 120 ms answer arrives (it may not parse as a
    // full detail, but it is not a timeout).
    Object? error;
    try {
      await api.getAdvisorStudent('ITK47A', 9);
    } catch (e) {
      error = e;
    }
    expect(error, isNot(isA<ApiException>()));
  });

  testWidgets(
    'count axis: room for 3 digits at 1.3, whole numbers on one line',
    (tester) async {
      late AxisTitles titles;
      late double plainWidth;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              plainWidth = countAxisTitles(
                context,
                125,
              ).sideTitles.reservedSize;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: Builder(
                  builder: (context) {
                    titles = countAxisTitles(context, 125);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
      expect(titles.sideTitles.reservedSize, greaterThan(plainWidth));
      expect(titles.sideTitles.reservedSize, greaterThan(22));
      // fl_chart also asks for the top value (e.g. 104.4): it is not drawn.
      expect(
        titles.sideTitles.getTitlesWidget(104.4, _meta()),
        isA<SizedBox>(),
      );
      final label = titles.sideTitles.getTitlesWidget(100, _meta()) as Padding;
      final text = label.child! as Text;
      expect(text.data, '100');
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    },
  );

  testWidgets('tinted cards stay dark in dark mode and light in light mode', (
    tester,
  ) async {
    final seen = <Brightness, Color>{};
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: theme,
          home: Builder(
            builder: (context) {
              seen[theme.brightness] = context.tint(Colors.deepOrange);
              return const SizedBox();
            },
          ),
        ),
      );
    }
    expect(seen[Brightness.light]!.computeLuminance(), greaterThan(0.8));
    expect(seen[Brightness.dark]!.computeLuminance(), lessThan(0.1));
  });
}

TitleMeta _meta() => TitleMeta(
  min: 0,
  max: 125,
  parentAxisSize: 200,
  axisPosition: 0,
  appliedInterval: 25,
  sideTitles: const SideTitles(),
  formattedValue: '',
  axisSide: AxisSide.left,
  rotationQuarterTurns: 0,
);
