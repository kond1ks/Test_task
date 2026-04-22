class KanbanTask {
  KanbanTask({
    required this.indicatorToMoId,
    required this.parentId,
    required this.name,
    required this.order,
  });

  final int indicatorToMoId;
  int parentId;
  final String name;
  int order;

  factory KanbanTask.fromJson(Map<String, dynamic> json) {
    return KanbanTask(
      indicatorToMoId: _toInt(json['indicator_to_mo_id']),
      parentId: _toInt(json['parent_id']),
      name: (json['name'] ?? '').toString().trim(),
      order: _toInt(json['order']),
    );
  }

  KanbanTask copy() {
    return KanbanTask(
      indicatorToMoId: indicatorToMoId,
      parentId: parentId,
      name: name,
      order: order,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }
}
