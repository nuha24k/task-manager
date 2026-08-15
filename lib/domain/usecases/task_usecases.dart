import 'package:fpdart/fpdart.dart' hide Task;
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;
  GetTasksUseCase(this.repository);

  Future<Either<Exception, List<Task>>> call(String workspaceId) {
    return repository.getTasks(workspaceId);
  }
}

class WatchTasksUseCase {
  final TaskRepository repository;
  WatchTasksUseCase(this.repository);

  Stream<List<Task>> call(String workspaceId) {
    return repository.watchTasks(workspaceId);
  }
}

class CreateTaskUseCase {
  final TaskRepository repository;
  CreateTaskUseCase(this.repository);

  Future<Either<Exception, Task>> call(Task task) {
    return repository.createTask(task);
  }
}

class UpdateTaskUseCase {
  final TaskRepository repository;
  UpdateTaskUseCase(this.repository);

  Future<Either<Exception, void>> call(Task task) {
    return repository.updateTask(task);
  }
}

class DeleteTaskUseCase {
  final TaskRepository repository;
  DeleteTaskUseCase(this.repository);

  Future<Either<Exception, void>> call(String taskId) {
    return repository.deleteTask(taskId);
  }
}

class ReorderTaskUseCase {
  final TaskRepository repository;
  ReorderTaskUseCase(this.repository);

  Future<Either<Exception, void>> call({
    required String taskId,
    required TaskStatus newStatus,
    required int newPosition,
  }) {
    return repository.reorderTask(
      taskId: taskId,
      newStatus: newStatus,
      newPosition: newPosition,
    );
  }
}
