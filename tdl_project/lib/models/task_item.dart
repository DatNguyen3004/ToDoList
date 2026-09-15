enum TaskContentType { drawing, text, image }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.contentType,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.richTextJson,
    this.dueDate,
    this.isCompleted = false,
    this.isDeleted = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? richTextJson;
  final TaskContentType contentType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isDeleted;

  TaskItem copyWith({
    String? title,
    String? description,
    String? richTextJson,
    bool clearDescription = false,
    DateTime? dueDate,
    DateTime? updatedAt,
    bool clearDueDate = false,
    bool? isCompleted,
    bool? isDeleted,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      richTextJson: richTextJson ?? this.richTextJson,
      contentType: contentType,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
