import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_goal.dart';
import '../../domain/usecases/goal_usecases.dart';

// --- Events ---
abstract class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => [];
}

class WatchGoalsRequested extends GoalEvent {
  final String taskId;
  const WatchGoalsRequested(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class CreateGoalRequested extends GoalEvent {
  final TaskGoal goal;
  const CreateGoalRequested(this.goal);
  @override
  List<Object?> get props => [goal];
}

class UpdateGoalRequested extends GoalEvent {
  final TaskGoal goal;
  const UpdateGoalRequested(this.goal);
  @override
  List<Object?> get props => [goal];
}

class ToggleGoalRequested extends GoalEvent {
  final TaskGoal goal;
  const ToggleGoalRequested(this.goal);
  @override
  List<Object?> get props => [goal];
}

class DeleteGoalRequested extends GoalEvent {
  final String goalId;
  const DeleteGoalRequested(this.goalId);
  @override
  List<Object?> get props => [goalId];
}

// --- States ---
abstract class GoalState extends Equatable {
  const GoalState();
  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalLoaded extends GoalState {
  final List<TaskGoal> goals;
  const GoalLoaded(this.goals);
  @override
  List<Object?> get props => [goals];
}

class GoalError extends GoalState {
  final String message;
  const GoalError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final WatchGoalsUseCase watchGoalsUseCase;
  final CreateGoalUseCase createGoalUseCase;
  final UpdateGoalUseCase updateGoalUseCase;
  final DeleteGoalUseCase deleteGoalUseCase;

  GoalBloc({
    required this.watchGoalsUseCase,
    required this.createGoalUseCase,
    required this.updateGoalUseCase,
    required this.deleteGoalUseCase,
  }) : super(GoalInitial()) {
    on<WatchGoalsRequested>(_onWatchGoalsRequested);
    on<CreateGoalRequested>(_onCreateGoalRequested);
    on<UpdateGoalRequested>(_onUpdateGoalRequested);
    on<ToggleGoalRequested>(_onToggleGoalRequested);
    on<DeleteGoalRequested>(_onDeleteGoalRequested);
  }

  Future<void> _onWatchGoalsRequested(
    WatchGoalsRequested event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());
    try {
      await emit.forEach<List<TaskGoal>>(
        watchGoalsUseCase(event.taskId),
        onData: (goals) => GoalLoaded(goals),
        onError: (error, stackTrace) => GoalError(error.toString()),
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(GoalError(e.toString()));
      }
    }
  }

  Future<void> _onCreateGoalRequested(
    CreateGoalRequested event,
    Emitter<GoalState> emit,
  ) async {
    final result = await createGoalUseCase(event.goal);
    result.fold(
      (failure) {
        if (!emit.isDone) emit(GoalError(failure.toString()));
      },
      (_) {},
    );
  }

  Future<void> _onUpdateGoalRequested(
    UpdateGoalRequested event,
    Emitter<GoalState> emit,
  ) async {
    final result = await updateGoalUseCase(event.goal);
    result.fold(
      (failure) {
        if (!emit.isDone) emit(GoalError(failure.toString()));
      },
      (_) {},
    );
  }

  Future<void> _onToggleGoalRequested(
    ToggleGoalRequested event,
    Emitter<GoalState> emit,
  ) async {
    final toggled = event.goal.copyWith(isCompleted: !event.goal.isCompleted);
    if (state is GoalLoaded) {
      final current = (state as GoalLoaded).goals;
      final updated = current.map((g) => g.id == toggled.id ? toggled : g).toList();
      emit(GoalLoaded(updated));
    }
    final result = await updateGoalUseCase(toggled);
    result.fold(
      (failure) {
        if (!emit.isDone) emit(GoalError(failure.toString()));
      },
      (_) {},
    );
  }

  Future<void> _onDeleteGoalRequested(
    DeleteGoalRequested event,
    Emitter<GoalState> emit,
  ) async {
    if (state is GoalLoaded) {
      final current = (state as GoalLoaded).goals;
      final updated = current.where((g) => g.id != event.goalId).toList();
      emit(GoalLoaded(updated));
    }
    final result = await deleteGoalUseCase(event.goalId);
    result.fold(
      (failure) {
        if (!emit.isDone) emit(GoalError(failure.toString()));
      },
      (_) {},
    );
  }
}
