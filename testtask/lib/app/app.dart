import 'package:flutter/material.dart';
import 'package:testtask/core/theme/app_theme.dart';
import 'package:testtask/features/kanban/data/kanban_repository.dart';
import 'package:testtask/features/kanban/data/kpi_drive_api.dart';
import 'package:testtask/features/kanban/presentation/controllers/kanban_controller.dart';
import 'package:testtask/features/kanban/presentation/pages/kanban_board_page.dart';

class KanbanApp extends StatefulWidget {
  const KanbanApp({super.key});

  @override
  State<KanbanApp> createState() => _KanbanAppState();
}

class _KanbanAppState extends State<KanbanApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  late final KanbanController _controller = KanbanController(
    KanbanRepository(KpiDriveApi()),
  );

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KPI Drive Kanban',
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: KanbanBoardPage(
        controller: _controller,
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
