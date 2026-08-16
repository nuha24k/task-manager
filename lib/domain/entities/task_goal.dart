import 'package:equatable/equatable.dart';
import 'task.dart';

class TaskGoal extends Equatable {
  final String id;
  final String taskId;
  final String title;
  final String projectName;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime createdAt;

  const TaskGoal({
    required this.id,
    required this.taskId,
    required this.title,
    this.projectName = 'Charty App',
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
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
        dueDate,
        createdAt,
      ];
}
