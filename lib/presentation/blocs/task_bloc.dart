import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/task_usecases.dart';

// --- Events ---
abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class SubscribeToBoard extends TaskEvent {
  final String workspaceId;
  const SubscribeToBoard(this.workspaceId);
  @override
  List<Object?> get props => [workspaceId];
}

class TaskListUpdated extends TaskEvent {
  final List<Task> tasks;
  const TaskListUpdated(this.tasks);
  @override
  List<Object?> get props => [tasks];
}

class CreateTaskRequested extends TaskEvent {
  final Task task;
  const CreateTaskRequested(this.task);
  @override
  List<Object?> get props => [task];
}

class TaskMoved extends TaskEvent {
  final String taskId;
  final TaskStatus newStatus;
  final int newPosition;
  const TaskMoved({
    required this.taskId,
    required this.newStatus,
    required this.newPosition,
  });
  @override
  List<Object?> get props => [taskId, newStatus, newPosition];
}

class DeleteTaskRequested extends TaskEvent {
  final String taskId;
  const DeleteTaskRequested(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

// --- States ---
abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  const TaskLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks];
}

class TaskError extends TaskState {
  final String message;
  final List<Task>? previousTasks;
  const TaskError(this.message, {this.previousTasks});
  @override
  List<Object?> get props => [message, previousTasks];
}

// --- BLoC ---
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final WatchTasksUseCase watchTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final ReorderTaskUseCase reorderTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;

  StreamSubscription<List<Task>>? _tasksSubscription;

  TaskBloc({
    required this.watchTasksUseCase,
    required this.createTaskUseCase,
    required this.reorderTaskUseCase,
    required this.deleteTaskUseCase,
  }) : super(TaskInitial()) {
    on<SubscribeToBoard>(_onSubscribeToBoard);
    on<TaskListUpdated>(_onTaskListUpdated);
    on<CreateTaskRequested>(_onCreateTaskRequested);
    on<TaskMoved>(_onTaskMoved);
    on<DeleteTaskRequested>(_onDeleteTaskRequested);
  }

  void _onSubscribeToBoard(SubscribeToBoard event, Emitter<TaskState> emit) {
    emit(TaskLoading());
    _tasksSubscription?.cancel();
    _tasksSubscription = watchTasksUseCase(event.workspaceId).listen(
      (List<Task> tasks) {
        add(TaskListUpdated(tasks));
      },
      onError: (Object error) {
        emit(TaskError(error.toString()));
      },
    );
  }

  void _onTaskListUpdated(TaskListUpdated event, Emitter<TaskState> emit) {
    emit(TaskLoaded(event.tasks));
  }

  Future<void> _onCreateTaskRequested(
    CreateTaskRequested event,
    Emitter<TaskState> emit,
  ) async {
    final result = await createTaskUseCase(event.task);
    result.fold(
      (failure) => emit(TaskError(failure.toString())),
      (_) {},
    );
  }

  Future<void> _onTaskMoved(TaskMoved event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      final currentTasks = (state as TaskLoaded).tasks;
      
      // Optimistic Update
      final updatedTasks = currentTasks.map((t) {
        if (t.id == event.taskId) {
          return t.copyWith(
            status: event.newStatus,
            position: event.newPosition,
          );
        }
        return t;
      }).toList();

      emit(TaskLoaded(updatedTasks));

      final result = await reorderTaskUseCase(
        taskId: event.taskId,
        newStatus: event.newStatus,
        newPosition: event.newPosition,
      );

      result.fold(
        (failure) {
          // Rollback on failure
          emit(TaskError('Reorder failed, rolling back: ${failure.toString()}', previousTasks: currentTasks));
          emit(TaskLoaded(currentTasks));
        },
        (_) {},
      );
    }
  }

  Future<void> _onDeleteTaskRequested(
    DeleteTaskRequested event,
    Emitter<TaskState> emit,
  ) async {
    final result = await deleteTaskUseCase(event.taskId);
    result.fold(
      (failure) => emit(TaskError(failure.toString())),
      (_) {},
    );
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
