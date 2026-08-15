import 'package:fpdart/fpdart.dart' hide Task;
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  TaskRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Exception, List<Task>>> getTasks(String workspaceId) async {
    try {
      final tasks = await remoteDataSource.getTasks(workspaceId);
      return Right(tasks);
    } catch (e) {
      return Left(Exception('Failed to get tasks: $e'));
    }
  }

  @override
  Stream<List<Task>> watchTasks(String workspaceId) {
    return remoteDataSource.watchTasks(workspaceId);
  }

  @override
  Future<Either<Exception, Task>> createTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final created = await remoteDataSource.createTask(taskModel);
      return Right(created);
    } catch (e) {
      return Left(Exception('Failed to create task: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> updateTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      await remoteDataSource.updateTask(taskModel);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to update task: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> deleteTask(String taskId) async {
    try {
      await remoteDataSource.deleteTask(taskId);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to delete task: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> reorderTask({
    required String taskId,
    required TaskStatus newStatus,
    required int newPosition,
  }) async {
    try {
      await remoteDataSource.reorderTask(
        taskId: taskId,
        newStatus: newStatus,
        newPosition: newPosition,
      );
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to reorder task: $e'));
    }
  }

  @override
  Stream<List<TaskComment>> watchComments(String taskId) {
    return remoteDataSource.watchComments(taskId);
  }

  @override
  Future<Either<Exception, void>> addComment(TaskComment comment) async {
    try {
      final commentModel = TaskCommentModel.fromEntity(comment);
      await remoteDataSource.addComment(commentModel);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to add comment: $e'));
    }
  }
}
