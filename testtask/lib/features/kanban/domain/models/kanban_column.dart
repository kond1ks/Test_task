import 'package:testtask/features/kanban/domain/models/kanban_task.dart';

class KanbanColumn {
  KanbanColumn({
    required this.folderId,
    required this.title,
    required this.tasks,
  });

  final int folderId;
  final String title;
  final List<KanbanTask> tasks;

  KanbanColumn copy() {
    return KanbanColumn(
      folderId: folderId,
      title: title,
      tasks: tasks.map((task) => task.copy()).toList(),
    );
  }
}
