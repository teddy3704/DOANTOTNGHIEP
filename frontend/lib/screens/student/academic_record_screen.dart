import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../portal_sources_screen.dart';
import 'portal/conduct_tab.dart';
import 'portal/decisions_tab.dart';
import 'portal/gpa_simulation_tab.dart';
import 'portal/program_tab.dart';
import 'portal/transcript_tab.dart';

/// V3 student "Học vụ": training-portal data joined with the LMS (P1–P5).
class AcademicRecordScreen extends StatefulWidget {
  final ApiService api;
  final int initialTab;
  const AcademicRecordScreen({
    super.key,
    required this.api,
    this.initialTab = 0,
  });

  static const tabs = [
    'Bảng điểm',
    'Chương trình',
    'Mô phỏng GPA',
    'Rèn luyện',
    'Quyết định',
  ];

  @override
  State<AcademicRecordScreen> createState() => _AcademicRecordScreenState();
}

class _AcademicRecordScreenState extends State<AcademicRecordScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: AcademicRecordScreen.tabs.length,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Học vụ'),
      actions: [
        IconButton(
          tooltip: 'Nguồn dữ liệu',
          icon: const Icon(Icons.verified_user_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PortalSourcesScreen(api: widget.api),
            ),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [for (final t in AcademicRecordScreen.tabs) Tab(text: t)],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        TranscriptTab(api: widget.api),
        ProgramTab(api: widget.api),
        GpaSimulationTab(api: widget.api),
        ConductTab(api: widget.api),
        DecisionsTab(
          api: widget.api,
          onOpenSimulation: () => _tabs.animateTo(2),
        ),
      ],
    ),
  );
}
