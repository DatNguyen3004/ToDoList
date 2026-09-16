import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/task_store.dart';
import '../models/task_item.dart';

class TaskController extends ChangeNotifier {
  TaskController({TaskStore? store}) : _store = store ?? MemoryTaskStore();

  TaskStore _store;
  final List<TaskItem> _tasks = [];
  Future<void> _pendingWrite = Future.value();
  int _idSequence = 0;
  int _storeGeneration = 0;

  String _newTaskId(DateTime now) =>
      '${now.microsecondsSinceEpoch}-${_idSequence++}';

  Future<void> load() async {
    final generation = _storeGeneration;
    final storedTasks = await _store.loadTasks();
    if (generation != _storeGeneration) return;
    _tasks
      ..clear()
      ..addAll(storedTasks);
    notifyListeners();
  }

  Future<void> useStore(TaskStore store) async {
    await _pendingWrite;
    _storeGeneration++;
    _store = store;
    _tasks.clear();
    notifyListeners();
    await load();
  }

  List<TaskItem> get activeTasks =>
      List.unmodifiable(_tasks.where((task) => !task.isDeleted));

  List<TaskItem> get deletedTasks =>
      List.unmodifiable(_tasks.where((task) => task.isDeleted));

  Future<void> get pendingWrites => _pendingWrite;

  void addTextTask({
    required String title,
    String? description,
    String? richTextJson,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    _tasks.add(
      TaskItem(
        id: _newTaskId(now),
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
    _commit(changedId: _tasks.last.id);
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

  void addDrawingTask({
    required String title,
    required String drawingJson,
    required int strokeCount,
  }) {
    final now = DateTime.now();
    _tasks.add(
      TaskItem(
        id: _newTaskId(now),
        title: title.trim(),
        description: '$strokeCount nét vẽ',
        drawingJson: drawingJson,
        contentType: TaskContentType.drawing,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _commit(changedId: _tasks.last.id);
  }

  void updateDrawingTask({
    required String id,
    required String title,
    required String drawingJson,
    required int strokeCount,
  }) {
    _update(
      id,
      (task) => task.copyWith(
        title: title.trim(),
        description: '$strokeCount nét vẽ',
        drawingJson: drawingJson,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void addImageTask({
    required String title,
    required String imageDataJson,
    String? description,
  }) {
    final now = DateTime.now();
    _tasks.add(
      TaskItem(
        id: _newTaskId(now),
        title: title.trim(),
        description: description?.trim().isEmpty ?? true
            ? null
            : description!.trim(),
        imageDataJson: imageDataJson,
        contentType: TaskContentType.image,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _commit(changedId: _tasks.last.id);
  }

  void updateImageTask({
    required String id,
    required String title,
    required String imageDataJson,
    String? description,
  }) {
    _update(
      id,
      (task) => task.copyWith(
        title: title.trim(),
        description: description?.trim().isEmpty ?? true
            ? null
            : description!.trim(),
        clearDescription: description?.trim().isEmpty ?? true,
        imageDataJson: imageDataJson,
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
    _commit(deletedId: id);
  }

  void _update(String id, TaskItem Function(TaskItem task) transform) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    _tasks[index] = transform(_tasks[index]);
    _commit(changedId: id);
  }

  void _commit({String? changedId, String? deletedId}) {
    notifyListeners();
    final snapshot = List<TaskItem>.of(_tasks);
    final changedIds = changedId == null ? <String>{} : {changedId};
    final deletedIds = deletedId == null ? <String>{} : {deletedId};
    _pendingWrite = _pendingWrite
        .then(
          (_) => _store.saveTasks(
            snapshot,
            changedIds: changedIds,
            deletedIds: deletedIds,
          ),
        )
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Không thể lưu dữ liệu TDL: $error');
        });
    unawaited(_pendingWrite);
  }
}
