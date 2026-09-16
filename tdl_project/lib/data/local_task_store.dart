import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/task_item.dart';
import 'task_store.dart';

class LocalTaskStore implements TaskStore {
  LocalTaskStore._(this._box);

  static const _boxName = 'tdl_guest_storage';
  static const _tasksKey = 'tasks';
  static const _guestModeKey = 'guest_mode_selected';

  final Box<String> _box;

  bool get hasSelectedGuestMode => _box.get(_guestModeKey) == 'true';

  Future<void> rememberGuestMode() => _box.put(_guestModeKey, 'true');

  static Future<LocalTaskStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(_boxName);
    return LocalTaskStore._(box);
  }

  @override
  Future<List<TaskItem>> loadTasks() async {
    final source = _box.get(_tasksKey);
    if (source == null || source.isEmpty) return const [];

    try {
      final decoded = jsonDecode(source) as List<dynamic>;
      return decoded
          .map(
            (item) => TaskItem.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList();
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> saveTasks(
    List<TaskItem> tasks, {
    Set<String> changedIds = const {},
    Set<String> deletedIds = const {},
  }) {
    return _box.put(
      _tasksKey,
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }
}
