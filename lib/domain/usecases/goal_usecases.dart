import 'package:fpdart/fpdart.dart';
import '../entities/task_goal.dart';
import '../repositories/task_repository.dart';

class WatchGoalsUseCase {
  final TaskRepository repository;
  WatchGoalsUseCase(this.repository);

  Stream<List<TaskGoal>> call(String taskId) {
    return repository.watchGoals(taskId);
  }
}

class CreateGoalUseCase {
  final TaskRepository repository;
  CreateGoalUseCase(this.repository);

  Future<Either<Exception, TaskGoal>> call(TaskGoal goal) {
    return repository.createGoal(goal);
  }
}

class UpdateGoalUseCase {
  final TaskRepository repository;
  UpdateGoalUseCase(this.repository);

  Future<Either<Exception, void>> call(TaskGoal goal) {
    return repository.updateGoal(goal);
  }
}

class DeleteGoalUseCase {
  final TaskRepository repository;
  DeleteGoalUseCase(this.repository);

  Future<Either<Exception, void>> call(String goalId) {
    return repository.deleteGoal(goalId);
  }
}
