import 'package:fpdart/fpdart.dart' hide Task;
import '../entities/task.dart';
import '../entities/task_goal.dart';

abstract class TaskRepository {
  Future<Either<Exception, List<Task>>> getTasks(String workspaceId);
  Stream<List<Task>> watchTasks(String workspaceId);
  Future<Either<Exception, Task>> createTask(Task task);
  Future<Either<Exception, void>> updateTask(Task task);
  Future<Either<Exception, void>> deleteTask(String taskId);
  Future<Either<Exception, void>> reorderTask({
    required String taskId,
    required TaskStatus newStatus,
    required int newPosition,
  });

  // Comments / Realtime Chat
  Stream<List<TaskComment>> watchComments(String taskId);
  Future<Either<Exception, void>> addComment(TaskComment comment);

  // Goals
  Stream<List<TaskGoal>> watchGoals(String taskId);
  Future<Either<Exception, TaskGoal>> createGoal(TaskGoal goal);
  Future<Either<Exception, void>> updateGoal(TaskGoal goal);
  Future<Either<Exception, void>> deleteGoal(String goalId);
}
