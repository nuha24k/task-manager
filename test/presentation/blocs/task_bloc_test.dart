import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:mocktail/mocktail.dart';
import 'package:task_management/domain/usecases/task_usecases.dart';
import 'package:task_management/presentation/blocs/task_bloc.dart';

import '../../helpers/dummy_data.dart';

class MockWatchTasksUseCase extends Mock implements WatchTasksUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}
class MockReorderTaskUseCase extends Mock implements ReorderTaskUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

void main() {
  late MockWatchTasksUseCase mockWatchTasksUseCase;
  late MockCreateTaskUseCase mockCreateTaskUseCase;
  late MockUpdateTaskUseCase mockUpdateTaskUseCase;
  late MockReorderTaskUseCase mockReorderTaskUseCase;
  late MockDeleteTaskUseCase mockDeleteTaskUseCase;
  late TaskBloc taskBloc;

  setUp(() {
    mockWatchTasksUseCase = MockWatchTasksUseCase();
    mockCreateTaskUseCase = MockCreateTaskUseCase();
    mockUpdateTaskUseCase = MockUpdateTaskUseCase();
    mockReorderTaskUseCase = MockReorderTaskUseCase();
    mockDeleteTaskUseCase = MockDeleteTaskUseCase();

    taskBloc = TaskBloc(
      watchTasksUseCase: mockWatchTasksUseCase,
      createTaskUseCase: mockCreateTaskUseCase,
      updateTaskUseCase: mockUpdateTaskUseCase,
      reorderTaskUseCase: mockReorderTaskUseCase,
      deleteTaskUseCase: mockDeleteTaskUseCase,
    );

    registerFallbackValue(tTask);
  });

  tearDown(() {
    taskBloc.close();
  });

  test('initial state should be TaskInitial', () {
    expect(taskBloc.state, equals(TaskInitial()));
  });

  group('SubscribeToBoard', () {
    blocTest<TaskBloc, TaskState>(
      'should emit [TaskLoading, TaskLoaded] when watchTasks stream emits data successfully',
      build: () {
        when(() => mockWatchTasksUseCase('ws1'))
            .thenAnswer((_) => Stream.value(tTasks));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const SubscribeToBoard('ws1')),
      expect: () => [
        TaskLoading(),
        TaskLoaded(tTasks),
      ],
      verify: (_) {
        verify(() => mockWatchTasksUseCase('ws1')).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should emit [TaskLoading, TaskError] when stream emits error',
      build: () {
        when(() => mockWatchTasksUseCase('ws1'))
            .thenAnswer((_) => Stream.error('Stream failure'));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const SubscribeToBoard('ws1')),
      expect: () => [
        TaskLoading(),
        const TaskError('Stream failure'),
      ],
    );
  });

  group('CreateTaskRequested', () {
    blocTest<TaskBloc, TaskState>(
      'should call createTaskUseCase when CreateTaskRequested is added',
      build: () {
        when(() => mockCreateTaskUseCase(any()))
            .thenAnswer((_) async => Right(tTask));
        return taskBloc;
      },
      act: (bloc) => bloc.add(CreateTaskRequested(tTask)),
      expect: () => [],
      verify: (_) {
        verify(() => mockCreateTaskUseCase(tTask)).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should emit TaskError when createTaskUseCase returns Left failure',
      build: () {
        when(() => mockCreateTaskUseCase(any()))
            .thenAnswer((_) async => Left(Exception('Creation failed')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(CreateTaskRequested(tTask)),
      expect: () => [
        isA<TaskError>(),
      ],
    );
  });

  group('UpdateTaskRequested', () {
    blocTest<TaskBloc, TaskState>(
      'should call updateTaskUseCase when UpdateTaskRequested is added',
      build: () {
        when(() => mockUpdateTaskUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return taskBloc;
      },
      act: (bloc) => bloc.add(UpdateTaskRequested(tTask)),
      expect: () => [],
      verify: (_) {
        verify(() => mockUpdateTaskUseCase(tTask)).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should emit TaskError when updateTaskUseCase returns Left failure',
      build: () {
        when(() => mockUpdateTaskUseCase(any()))
            .thenAnswer((_) async => Left(Exception('Update failed')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(UpdateTaskRequested(tTask)),
      expect: () => [
        isA<TaskError>(),
      ],
      verify: (_) {
        verify(() => mockUpdateTaskUseCase(tTask)).called(1);
      },
    );
  });

  group('TaskMoved', () {
    blocTest<TaskBloc, TaskState>(
      'should optimistically update task state when TaskMoved event is triggered',
      seed: () => TaskLoaded(tTasks),
      build: () {
        when(() => mockReorderTaskUseCase(
              taskId: 't1',
              newStatus: TaskStatus.inProgress,
              newPosition: 1,
            )).thenAnswer((_) async => const Right(null));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const TaskMoved(
        taskId: 't1',
        newStatus: TaskStatus.inProgress,
        newPosition: 1,
      )),
      expect: () => [
        TaskLoaded([
          tTask.copyWith(status: TaskStatus.inProgress, position: 1),
        ]),
      ],
      verify: (_) {
        verify(() => mockReorderTaskUseCase(
              taskId: 't1',
              newStatus: TaskStatus.inProgress,
              newPosition: 1,
            )).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'should emit TaskError and rollback state when reorder fails',
      seed: () => TaskLoaded(tTasks),
      build: () {
        when(() => mockReorderTaskUseCase(
              taskId: 't1',
              newStatus: TaskStatus.done,
              newPosition: 2,
            )).thenAnswer((_) async => Left(Exception('Network timeout')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const TaskMoved(
        taskId: 't1',
        newStatus: TaskStatus.done,
        newPosition: 2,
      )),
      expect: () => [
        TaskLoaded([
          tTask.copyWith(status: TaskStatus.done, position: 2),
        ]),
        TaskError('Reorder failed, rolling back: Exception: Network timeout', previousTasks: tTasks),
        TaskLoaded(tTasks),
      ],
    );
  });

  group('DeleteTaskRequested', () {
    blocTest<TaskBloc, TaskState>(
      'should call deleteTaskUseCase when DeleteTaskRequested is added',
      build: () {
        when(() => mockDeleteTaskUseCase('t1'))
            .thenAnswer((_) async => const Right(null));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const DeleteTaskRequested('t1')),
      expect: () => [],
      verify: (_) {
        verify(() => mockDeleteTaskUseCase('t1')).called(1);
      },
    );
  });
}
