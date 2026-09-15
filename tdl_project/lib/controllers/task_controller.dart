import 'package:flutter/foundation.dart';

import '../models/task_item.dart';

class TaskController extends ChangeNotifier {
  final List<TaskItem> _tasks = [];

  List<TaskItem> get activeTasks =>
      List.unmodifiable(_tasks.where((task) => !task.isDeleted));

  List<TaskItem> get deletedTasks =>
      List.unmodifiable(_tasks.where((task) => task.isDeleted));

  void addTextTask({
    required String title,
    String? description,
    String? richTextJson,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    _tasks.add(
      TaskItem(
        id: now.microsecondsSinceEpoch.toString(),
        title: title.trim(),
        description: description?.trim().isEmpty ?? true
            ? null
            : description!.trim(),
        richTextJson: richTextJson,
        contentType: TaskContentType.text,
        createdAt: now,
        updatedAt: now,
        dueDate: dueDate,
      ),
    );
    notifyListeners();
  }

  TaskItem? findById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  void updateTextTask({
    required String id,
    required String title,
    String? description,
    String? richTextJson,
  }) {
    _update(
      id,
      (task) => task.copyWith(
        title: title.trim(),
        description: description?.trim().isEmpty ?? true
            ? null
            : description!.trim(),
        clearDescription: description?.trim().isEmpty ?? true,
        richTextJson: richTextJson,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void toggleCompleted(String id) {
    _update(id, (task) => task.copyWith(isCompleted: !task.isCompleted));
  }

  void moveToTrash(String id) {
    _update(id, (task) => task.copyWith(isDeleted: true));
  }

  void restore(String id) {
    _update(id, (task) => task.copyWith(isDeleted: false));
  }

  void deleteForever(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  void _update(String id, TaskItem Function(TaskItem task) transform) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    _tasks[index] = transform(_tasks[index]);
    notifyListeners();
  }
}
