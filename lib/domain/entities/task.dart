import 'package:equatable/equatable.dart';

enum TaskStatus {
  todo,
  inProgress,
  done;

  String toDbValue() {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  static TaskStatus fromDbValue(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }
}

enum TaskPriority {
  low,
  medium,
  high;

  String toDbValue() {
    return name;
  }

  static TaskPriority fromDbValue(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }
}

class Task extends Equatable {
  final String id;
  final String workspaceId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final List<String> assigneeIds;
  final DateTime? dueDate;
  final int position;
  final double progress;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeIds = const [],
    this.dueDate,
    required this.position,
    this.progress = 0.0,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    List<String>? assigneeIds,
    DateTime? dueDate,
    int? position,
    double? progress,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      dueDate: dueDate ?? this.dueDate,
      position: position ?? this.position,
      progress: progress ?? this.progress,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        workspaceId,
        title,
        description,
        status,
        priority,
        assigneeIds,
        dueDate,
        position,
        progress,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

class TaskComment extends Equatable {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, taskId, userId, content, createdAt];
}
