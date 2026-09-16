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
    this.drawingJson,
    this.imageDataJson,
    this.dueDate,
    this.isCompleted = false,
    this.isDeleted = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? richTextJson;
  final String? drawingJson;
  final String? imageDataJson;
  final TaskContentType contentType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isDeleted;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      richTextJson: json['richTextJson'] as String?,
      drawingJson: json['drawingJson'] as String?,
      imageDataJson: json['imageDataJson'] as String?,
      contentType: TaskContentType.values.byName(
        json['contentType'] as String? ?? TaskContentType.text.name,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'richTextJson': richTextJson,
    'drawingJson': drawingJson,
    'imageDataJson': imageDataJson,
    'contentType': contentType.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'isCompleted': isCompleted,
    'isDeleted': isDeleted,
  };

  TaskItem copyWith({
    String? title,
    String? description,
    String? richTextJson,
    String? drawingJson,
    String? imageDataJson,
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
      drawingJson: drawingJson ?? this.drawingJson,
      imageDataJson: imageDataJson ?? this.imageDataJson,
      contentType: contentType,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
