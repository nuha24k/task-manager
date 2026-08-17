import 'package:equatable/equatable.dart';
import 'task.dart';

class TaskGoal extends Equatable {
  final String id;
  final String taskId; // Corresponds to project_id in DB
  final String title;
  final String projectName;
  final TaskPriority priority;
  final bool isCompleted;
  final List<String> assigneeIds; // Assignees per task/goal
  final DateTime? dueDate;
  final DateTime createdAt;

  String get projectId => taskId;

  const TaskGoal({
    required this.id,
    required this.taskId,
    required this.title,
    this.projectName = '',
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.assigneeIds = const [],
    this.dueDate,
    required this.createdAt,
  });

  TaskGoal copyWith({
    String? id,
    String? taskId,
    String? title,
    String? projectName,
    TaskPriority? priority,
    bool? isCompleted,
    List<String>? assigneeIds,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return TaskGoal(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      projectName: projectName ?? this.projectName,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        title,
        projectName,
        priority,
        isCompleted,
        assigneeIds,
        dueDate,
        createdAt,
      ];
}
