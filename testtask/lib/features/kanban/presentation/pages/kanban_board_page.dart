import 'dart:math' as math;

import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:testtask/features/kanban/domain/models/kanban_column.dart';
import 'package:testtask/features/kanban/presentation/controllers/kanban_controller.dart';

class KanbanBoardPage extends StatefulWidget {
  const KanbanBoardPage({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onToggleTheme,
  });

  final KanbanController controller;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<KanbanBoardPage> createState() => _KanbanBoardPageState();
}

class _KanbanBoardPageState extends State<KanbanBoardPage> {
  final ScrollController _boardScrollController = ScrollController();
  static const double _boardScrollStep = 420;

  @override
  void initState() {
    super.initState();
    widget.controller.loadBoard();
  }

  @override
  void dispose() {
    _boardScrollController.dispose();
    super.dispose();
  }

  Future<void> _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) async {
    try {
      final saved = await widget.controller.reorderItem(
        oldItemIndex: oldItemIndex,
        oldListIndex: oldListIndex,
        newItemIndex: newItemIndex,
        newListIndex: newListIndex,
      );
      if (!mounted || !saved) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изменения сохранены')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  Future<void> _scrollBoardBy(double delta) async {
    if (!_boardScrollController.hasClients) {
      return;
    }
    final position = _boardScrollController.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    await _boardScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isDark = widget.isDark;
        final screenWidth = MediaQuery.of(context).size.width;
        final compact = screenWidth < 390;
        final isDesktopLayout = screenWidth >= 1100;
        final isWebLike = kIsWeb || isDesktopLayout;
        final contentWidth = isDesktopLayout ? math.min(1760.0, screenWidth) : screenWidth;
        final columnWidth = math.min(
          compact ? 312.0 : (isDesktopLayout ? 360.0 : 350.0),
          math.max(
            compact ? 260.0 : (isDesktopLayout ? 320.0 : 290.0),
            screenWidth * (compact ? 0.9 : (isDesktopLayout ? 0.3 : 0.86)),
          ),
        );

        final bgGradient = isDark
            ? const [Color(0xFF0B1020), Color(0xFF111B36), Color(0xFF0F172A)]
            : const [Color(0xFFEFF4FF), Color(0xFFF8FAFF), Color(0xFFF3F7FF)];

        final listBg = isDark ? const Color(0xFF121A2F) : Colors.white;
        final listBorder = isDark ? const Color(0xFF273249) : const Color(0xFFD9E4F5);
        final dividerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgGradient,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                children: [
                  _BoardHeader(
                    columnsCount: widget.controller.columns.length,
                    totalTasks: widget.controller.columns.fold(
                      0,
                      (sum, item) => sum + item.tasks.length,
                    ),
                    isBusy: widget.controller.isSaving,
                    isDark: isDark,
                    compact: compact,
                    onRefresh: widget.controller.isLoading || widget.controller.isSaving
                        ? null
                        : widget.controller.loadBoard,
                    onToggleTheme: widget.onToggleTheme,
                  ),
                  if (widget.controller.isSaving)
                    const LinearProgressIndicator(minHeight: 2, color: Color(0xFF22C55E)),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: switch ((widget.controller.isLoading, widget.controller.error, widget.controller.columns.isEmpty)) {
                        (true, _, _) => _BoardSkeletonView(
                            compact: compact,
                            isDark: isDark,
                          ),
                        (false, final String error, _) => _ErrorView(
                            error: error,
                            isDark: isDark,
                            onRetry: widget.controller.loadBoard,
                          ),
                        (false, null, true) => _EmptyView(
                            isDark: isDark,
                          ),
                        _ => RefreshIndicator(
                            onRefresh: widget.controller.loadBoard,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                compact ? 6 : (isDesktopLayout ? 14 : 8),
                                8,
                                compact ? 6 : (isDesktopLayout ? 14 : 8),
                                20,
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      Expanded(
                                        child: PrimaryScrollController(
                                          controller: _boardScrollController,
                                          child: DragAndDropLists(
                                            children: _buildDragLists(
                                              columns: widget.controller.columns,
                                              compact: compact,
                                              isDark: isDark,
                                              isSaving: widget.controller.isSaving,
                                            ),
                                            onItemReorder: _onItemReorder,
                                            onListReorder: (oldListIndex, newListIndex) {},
                                            listWidth: columnWidth,
                                            listDecoration: BoxDecoration(
                                              color: listBg,
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(color: listBorder),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(
                                                    alpha: isDark ? 0.2 : 0.06,
                                                  ),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            listPadding: const EdgeInsets.symmetric(horizontal: 8),
                                            itemDivider: Divider(height: 0, color: dividerColor),
                                            axis: Axis.horizontal,
                                            listDragOnLongPress: !isWebLike,
                                            itemDragOnLongPress: !isWebLike,
                                            addLastItemTargetHeightToTop: false,
                                            lastItemTargetHeight: 56,
                                            itemGhost: const Opacity(
                                              opacity: 0.35,
                                              child: Card(child: SizedBox(height: 74)),
                                            ),
                                            scrollController: _boardScrollController,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!compact)
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: _ScrollArrowButton(
                                          icon: Icons.chevron_left_rounded,
                                          onTap: () => _scrollBoardBy(-_boardScrollStep),
                                        ),
                                      ),
                                    ),
                                  if (!compact)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: _ScrollArrowButton(
                                          icon: Icons.chevron_right_rounded,
                                          onTap: () => _scrollBoardBy(_boardScrollStep),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      },
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<DragAndDropList> _buildDragLists({
    required List<KanbanColumn> columns,
    required bool compact,
    required bool isDark,
    required bool isSaving,
  }) {
    final titleColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final badgeBg = isDark ? const Color(0xFF253249) : const Color(0xFFE2E8F0);
    final badgeText = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF475569);
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFDBE4F3);
    final taskTitle = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final taskMeta = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return columns.asMap().entries.map((entry) {
      final columnIndex = entry.key;
      final column = entry.value;
      return DragAndDropList(
        canDrag: !isSaving,
        header: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 10 : 14, compact ? 12 : 14, compact ? 10 : 14, 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: compact ? 22 : 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  column.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(100)),
                child: Text(
                  '${column.tasks.length}',
                  style: TextStyle(color: badgeText, fontWeight: FontWeight.w700, fontSize: compact ? 11 : 12),
                ),
              ),
            ],
          ),
        ),
        children: column.tasks.asMap().entries.map((itemEntry) {
          final itemIndex = itemEntry.key;
          final task = itemEntry.value;
          final isLastItem = itemIndex == column.tasks.length - 1;
          return DragAndDropItem(
            canDrag: !isSaving,
            child: _AnimatedAppear(
              delayMs: math.min(450, (columnIndex * 70) + (itemIndex * 35)),
              child: Card(
                elevation: 2,
                color: cardBg,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                margin: EdgeInsets.fromLTRB(
                  compact ? 6 : 8,
                  compact ? 4 : 6,
                  compact ? 6 : 8,
                  isLastItem ? 28 : (compact ? 4 : 6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: cardBorder),
                ),
                child: ListTile(
                  minLeadingWidth: compact ? 20 : 24,
                  horizontalTitleGap: compact ? 8 : 12,
                  title: Text(
                    task.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 13 : 14,
                      color: taskTitle,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '№ ${task.order}  •  #${task.indicatorToMoId}',
                      style: TextStyle(fontSize: compact ? 11 : 12, color: taskMeta),
                    ),
                  ),
                  leading: const Icon(Icons.drag_indicator_rounded, color: Color(0xFF22C55E)),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }).toList();
  }
}

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({
    required this.columnsCount,
    required this.totalTasks,
    required this.isBusy,
    required this.isDark,
    required this.compact,
    required this.onRefresh,
    required this.onToggleTheme,
  });

  final int columnsCount;
  final int totalTasks;
  final bool isBusy;
  final bool isDark;
  final bool compact;
  final Future<void> Function()? onRefresh;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 12, 8, compact ? 8 : 12, 6),
      child: Container(
        padding: EdgeInsets.fromLTRB(compact ? 10 : 14, compact ? 10 : 12, 10, compact ? 10 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF22C55E), Color(0xFF16A34A)]
                : const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8))
                  .withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KANBAN KPI-DRIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 16 : 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Перетащите карточку для смены папки и порядка',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact) _HeaderChip(label: '$columnsCount папок'),
            if (!compact) const SizedBox(width: 8),
            _HeaderChip(label: '$totalTasks'),
            IconButton(
              onPressed: onToggleTheme,
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
              ),
              tooltip: 'Сменить тему',
            ),
            IconButton(
              onPressed: onRefresh,
              icon: Icon(
                isBusy ? Icons.sync_disabled_rounded : Icons.refresh_rounded,
                color: Colors.white,
              ),
              tooltip: 'Обновить',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScrollArrowButton extends StatelessWidget {
  const _ScrollArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC0F172A),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _AnimatedAppear extends StatelessWidget {
  const _AnimatedAppear({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delayMs),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
    );
  }
}

class _BoardSkeletonView extends StatefulWidget {
  const _BoardSkeletonView({required this.compact, required this.isDark});

  final bool compact;
  final bool isDark;

  @override
  State<_BoardSkeletonView> createState() => _BoardSkeletonViewState();
}

class _BoardSkeletonViewState extends State<_BoardSkeletonView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? const Color(0xFF18233B) : const Color(0xFFE2E8F0);
    final highlight = widget.isDark ? const Color(0xFF223150) : const Color(0xFFF1F5F9);
    final columnBg = widget.isDark ? const Color(0xFF121A2F) : Colors.white;
    final border = widget.isDark ? const Color(0xFF273249) : const Color(0xFFD9E4F5);
    final width = widget.compact ? 290.0 : 330.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = Color.lerp(base, highlight, _controller.value)!;
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(widget.compact ? 8 : 10, 10, widget.compact ? 8 : 10, 14),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) => Container(
            width: width,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: columnBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                5,
                (i) => Container(
                  margin: EdgeInsets.only(bottom: i == 4 ? 0 : 10),
                  height: i == 0 ? 24 : 72,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemCount: 3,
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  final String error;
  final bool isDark;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 46, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Задачи не найдены.\nПопробуйте обновить список.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
