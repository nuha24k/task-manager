import '../../domain/entities/task.dart';
import '../../domain/entities/task_goal.dart';

class TaskGoalModel extends TaskGoal {
  const TaskGoalModel({
    required super.id,
    required super.taskId,
    required super.title,
    super.projectName,
    super.priority,
    super.isCompleted,
    super.assigneeIds,
    super.dueDate,
    required super.createdAt,
  });

  factory TaskGoalModel.fromJson(Map<String, dynamic> json) {
    final rawAssignees = json['assignee_ids'];
    List<String> assignees = [];
    if (rawAssignees is List) {
      assignees = rawAssignees.map((e) => e.toString()).toList();
    }

    return TaskGoalModel(
      id: json['id'] as String,
      taskId: (json['project_id'] ?? json['task_id']) as String,
      title: json['title'] as String,
      projectName: json['project_name'] as String? ?? 'Charty App',
      priority: TaskPriority.fromDbValue(json['priority'] as String? ?? 'medium'),
      isCompleted: json['is_completed'] as bool? ?? false,
      assigneeIds: assignees,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'project_id': taskId,
      'title': title,
      'priority': priority.toDbValue(),
      'is_completed': isCompleted,
      'assignee_ids': assigneeIds,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  factory TaskGoalModel.fromEntity(TaskGoal goal) {
    return TaskGoalModel(
      id: goal.id,
      taskId: goal.taskId,
      title: goal.title,
      projectName: goal.projectName,
      priority: goal.priority,
      isCompleted: goal.isCompleted,
      assigneeIds: goal.assigneeIds,
      dueDate: goal.dueDate,
      createdAt: goal.createdAt,
    );
  }
}
