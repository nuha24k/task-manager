import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.workspaceId,
    required super.title,
    super.description,
    required super.status,
    required super.priority,
    super.assigneeIds,
    super.dueDate,
    required super.position,
    super.progress,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromDbValue(json['status'] as String? ?? 'todo'),
      priority: TaskPriority.fromDbValue(json['priority'] as String? ?? 'medium'),
      assigneeIds: json['assignee_ids'] != null
          ? List<String>.from(json['assignee_ids'])
          : const [],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      position: json['position'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'workspace_id': workspaceId,
      'title': title,
      'description': description,
      'status': status.toDbValue(),
      'priority': priority.toDbValue(),
      'assignee_ids': assigneeIds,
      'due_date': dueDate?.toIso8601String(),
      'position': position,
      'progress': progress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    if (createdBy != null && createdBy!.isNotEmpty) {
      map['created_by'] = createdBy;
    }
    return map;
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      workspaceId: task.workspaceId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      assigneeIds: task.assigneeIds,
      dueDate: task.dueDate,
      position: task.position,
      progress: task.progress,
      createdBy: task.createdBy,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
  }
}

class TaskCommentModel extends TaskComment {
  const TaskCommentModel({
    required super.id,
    required super.taskId,
    required super.userId,
    required super.content,
    required super.createdAt,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentModel(
      id: json['id'] as String,
      taskId: (json['project_id'] ?? json['task_id']) as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'project_id': taskId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  factory TaskCommentModel.fromEntity(TaskComment comment) {
    return TaskCommentModel(
      id: comment.id,
      taskId: comment.taskId,
      userId: comment.userId,
      content: comment.content,
      createdAt: comment.createdAt,
    );
  }
}
