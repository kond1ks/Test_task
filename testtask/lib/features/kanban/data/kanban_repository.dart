import 'package:testtask/features/kanban/data/kpi_drive_api.dart';
import 'package:testtask/features/kanban/domain/models/kanban_column.dart';
import 'package:testtask/features/kanban/domain/models/kanban_task.dart';

class KanbanRepository {
  KanbanRepository(this._api);

  final KpiDriveApi _api;

  Future<List<KanbanColumn>> loadColumns() async {
    final tasks = await _api.fetchTasks();
    return _groupTasks(tasks);
  }

  Future<void> saveColumnTasks(List<KanbanColumn> columns, Set<int> listIndexes) async {
    for (final listIndex in listIndexes) {
      final list = columns[listIndex];
      for (final task in list.tasks) {
        await _api.saveTaskField(
          indicatorToMoId: task.indicatorToMoId,
          fieldName: 'parent_id',
          fieldValue: '${task.parentId}',
        );
        await _api.saveTaskField(
          indicatorToMoId: task.indicatorToMoId,
          fieldName: 'order',
          fieldValue: '${task.order}',
        );
      }
    }
  }

  List<KanbanColumn> _groupTasks(List<KanbanTask> tasks) {
    final byFolder = <int, List<KanbanTask>>{};
    final tasksById = <int, KanbanTask>{};

    for (final task in tasks) {
      byFolder.putIfAbsent(task.parentId, () => []).add(task);
      tasksById[task.indicatorToMoId] = task;
    }

    final columns = byFolder.entries.map((entry) {
      final sorted = [...entry.value]..sort((a, b) => a.order.compareTo(b.order));
      final folderTask = tasksById[entry.key];
      final title = folderTask != null && folderTask.name.isNotEmpty
          ? _normalizeFolderTitle(folderTask.name)
          : 'Папка ${entry.key}';

      return KanbanColumn(
        folderId: entry.key,
        title: title,
        tasks: sorted,
      );
    }).toList();

    columns.sort((a, b) => a.folderId.compareTo(b.folderId));
    return columns;
  }

  String _normalizeFolderTitle(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'убить одноклассники аккаунт') {
      return 'Работа с аккаунтом в Одноклассниках';
    }
    return value.trim();
  }
}
