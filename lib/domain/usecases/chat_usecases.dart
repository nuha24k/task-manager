import 'package:fpdart/fpdart.dart' hide Task;
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class WatchCommentsUseCase {
  final TaskRepository repository;
  WatchCommentsUseCase(this.repository);

  Stream<List<TaskComment>> call(String taskId) {
    return repository.watchComments(taskId);
  }
}

class AddCommentUseCase {
  final TaskRepository repository;
  AddCommentUseCase(this.repository);

  Future<Either<Exception, void>> call(TaskComment comment) {
    return repository.addComment(comment);
  }
}
