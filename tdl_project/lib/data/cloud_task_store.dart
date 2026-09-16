import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_item.dart';
import 'task_store.dart';

class CloudTaskStore implements TaskStore {
  CloudTaskStore({required this.client, required this.userId});

  static const _table = 'tdl_tasks';
  static const _bucket = 'task-images';

  final SupabaseClient client;
  final String userId;

  @override
  Future<List<TaskItem>> loadTasks() async {
    final rows = await client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('updated_at');

    final tasks = <TaskItem>[];
    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      final imagePaths = (row['image_paths'] as List<dynamic>? ?? const [])
          .cast<String>();
      final encodedImages = <String>[];
      for (final path in imagePaths) {
        final bytes = await client.storage.from(_bucket).download(path);
        encodedImages.add(base64Encode(bytes));
      }

      tasks.add(
        TaskItem(
          id: row['id'] as String,
          title: row['title'] as String? ?? '',
          description: row['description'] as String?,
          richTextJson: row['rich_text_json'] as String?,
          drawingJson: row['drawing_json'] as String?,
          imageDataJson: encodedImages.isEmpty
              ? null
              : jsonEncode(encodedImages),
          contentType: TaskContentType.values.byName(
            row['content_type'] as String,
          ),
          createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
          dueDate: row['due_date'] == null
              ? null
              : DateTime.parse(row['due_date'] as String).toLocal(),
          isCompleted: row['is_completed'] as bool? ?? false,
          isDeleted: row['is_deleted'] as bool? ?? false,
        ),
      );
    }
    return tasks;
  }

  @override
  Future<void> saveTasks(
    List<TaskItem> tasks, {
    Set<String> changedIds = const {},
    Set<String> deletedIds = const {},
  }) async {
    for (final id in deletedIds) {
      final existing = await client
          .from(_table)
          .select('image_paths')
          .eq('user_id', userId)
          .eq('id', id)
          .maybeSingle();
      final imagePaths =
          (existing?['image_paths'] as List<dynamic>? ?? const [])
              .cast<String>();
      if (imagePaths.isNotEmpty) {
        await client.storage.from(_bucket).remove(imagePaths);
      }
      await client.from(_table).delete().eq('user_id', userId).eq('id', id);
    }

    for (final task in tasks.where((task) => changedIds.contains(task.id))) {
      final existing = await client
          .from(_table)
          .select('image_paths')
          .eq('user_id', userId)
          .eq('id', task.id)
          .maybeSingle();
      final previousPaths =
          (existing?['image_paths'] as List<dynamic>? ?? const [])
              .cast<String>();
      final imagePaths = await _syncImages(task, previousPaths);
      await client.from(_table).upsert({
        'id': task.id,
        'user_id': userId,
        'title': task.title,
        'description': task.description,
        'rich_text_json': task.richTextJson,
        'drawing_json': task.drawingJson,
        'image_paths': imagePaths,
        'content_type': task.contentType.name,
        'created_at': task.createdAt.toUtc().toIso8601String(),
        'updated_at': task.updatedAt.toUtc().toIso8601String(),
        'due_date': task.dueDate?.toUtc().toIso8601String(),
        'is_completed': task.isCompleted,
        'is_deleted': task.isDeleted,
      }, onConflict: 'user_id,id');
    }
  }

  Future<List<String>> _syncImages(
    TaskItem task,
    List<String> previousPaths,
  ) async {
    if (task.contentType != TaskContentType.image ||
        task.imageDataJson == null) {
      if (previousPaths.isNotEmpty) {
        await client.storage.from(_bucket).remove(previousPaths);
      }
      return const [];
    }

    final encodedImages = (jsonDecode(task.imageDataJson!) as List<dynamic>)
        .cast<String>();
    final paths = <String>[];
    for (var index = 0; index < encodedImages.length; index++) {
      final path = '$userId/${task.id}/image_$index';
      final bytes = Uint8List.fromList(base64Decode(encodedImages[index]));
      await client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      paths.add(path);
    }

    final removedPaths = previousPaths
        .where((path) => !paths.contains(path))
        .toList();
    if (removedPaths.isNotEmpty) {
      await client.storage.from(_bucket).remove(removedPaths);
    }
    return paths;
  }
}
