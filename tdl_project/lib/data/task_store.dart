import '../models/task_item.dart';

abstract interface class TaskStore {
  Future<List<TaskItem>> loadTasks();

  Future<void> saveTasks(
    List<TaskItem> tasks, {
    Set<String> changedIds = const {},
    Set<String> deletedIds = const {},
  });
}

class MemoryTaskStore implements TaskStore {
  List<TaskItem> _tasks = const [];

  @override
  Future<List<TaskItem>> loadTasks() async => List.of(_tasks);

  @override
  Future<void> saveTasks(
    List<TaskItem> tasks, {
    Set<String> changedIds = const {},
    Set<String> deletedIds = const {},
  }) async {
    _tasks = List.of(tasks);
  }
}
