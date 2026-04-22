import 'package:flutter/material.dart';
import 'package:testtask/features/kanban/data/kanban_repository.dart';
import 'package:testtask/features/kanban/domain/models/kanban_column.dart';

class KanbanController extends ChangeNotifier {
  KanbanController(this._repository);

  final KanbanRepository _repository;

  List<KanbanColumn> _columns = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  List<KanbanColumn> get columns => _columns;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> loadBoard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _columns = await _repository.loadColumns();
    } catch (e) {
      _error = 'Не удалось загрузить задачи: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reorderItem({
    required int oldItemIndex,
    required int oldListIndex,
    required int newItemIndex,
    required int newListIndex,
  }) async {
    if (_isSaving) {
      return false;
    }

    final snapshot = _columns.map((column) => column.copy()).toList();
    final item = _columns[oldListIndex].tasks.removeAt(oldItemIndex);
    _columns[newListIndex].tasks.insert(newItemIndex, item);
    _recalculateOrders();
    notifyListeners();

    try {
      _isSaving = true;
      notifyListeners();
      await _repository.saveColumnTasks(_columns, {oldListIndex, newListIndex});
      // Re-read board from server so browser refresh shows same state.
      _columns = await _repository.loadColumns();
      notifyListeners();
      return true;
    } catch (_) {
      _columns = snapshot;
      notifyListeners();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _recalculateOrders() {
    for (final column in _columns) {
      for (var index = 0; index < column.tasks.length; index++) {
        final task = column.tasks[index];
        task.order = index + 1;
        task.parentId = column.folderId;
      }
    }
  }
}
