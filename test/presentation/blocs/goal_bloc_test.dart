import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/domain/entities/task.dart';
import 'package:task_management/domain/entities/task_goal.dart';
import 'package:task_management/domain/usecases/goal_usecases.dart';
import 'package:task_management/presentation/blocs/goal_bloc.dart';

class MockWatchGoalsUseCase extends Mock implements WatchGoalsUseCase {}
class MockCreateGoalUseCase extends Mock implements CreateGoalUseCase {}
class MockUpdateGoalUseCase extends Mock implements UpdateGoalUseCase {}
class MockDeleteGoalUseCase extends Mock implements DeleteGoalUseCase {}

void main() {
  late GoalBloc goalBloc;
  late MockWatchGoalsUseCase mockWatchGoalsUseCase;
  late MockCreateGoalUseCase mockCreateGoalUseCase;
  late MockUpdateGoalUseCase mockUpdateGoalUseCase;
  late MockDeleteGoalUseCase mockDeleteGoalUseCase;

  final tGoal = TaskGoal(
    id: 'g1',
    taskId: 't1',
    title: 'Test Goal',
    projectName: 'Charty App',
    priority: TaskPriority.high,
    isCompleted: false,
    dueDate: DateTime(2026, 8, 25),
    createdAt: DateTime(2026, 8, 16),
  );

  setUp(() {
    mockWatchGoalsUseCase = MockWatchGoalsUseCase();
    mockCreateGoalUseCase = MockCreateGoalUseCase();
    mockUpdateGoalUseCase = MockUpdateGoalUseCase();
    mockDeleteGoalUseCase = MockDeleteGoalUseCase();

    goalBloc = GoalBloc(
      watchGoalsUseCase: mockWatchGoalsUseCase,
      createGoalUseCase: mockCreateGoalUseCase,
      updateGoalUseCase: mockUpdateGoalUseCase,
      deleteGoalUseCase: mockDeleteGoalUseCase,
    );
  });

  tearDown(() {
    goalBloc.close();
  });

  test('initial state should be GoalInitial', () {
    expect(goalBloc.state, equals(GoalInitial()));
  });

  blocTest<GoalBloc, GoalState>(
    'WatchGoalsRequested should emit [GoalLoading, GoalLoaded] when stream emits goals',
    build: () {
      when(() => mockWatchGoalsUseCase('t1')).thenAnswer((_) => Stream.value([tGoal]));
      return goalBloc;
    },
    act: (bloc) => bloc.add(const WatchGoalsRequested('t1')),
    expect: () => [
      GoalLoading(),
      GoalLoaded([tGoal]),
    ],
    verify: (_) {
      verify(() => mockWatchGoalsUseCase('t1')).called(1);
    },
  );

  blocTest<GoalBloc, GoalState>(
    'CreateGoalRequested should call createGoalUseCase',
    build: () {
      when(() => mockCreateGoalUseCase(tGoal)).thenAnswer((_) async => Right(tGoal));
      return goalBloc;
    },
    act: (bloc) => bloc.add(CreateGoalRequested(tGoal)),
    verify: (_) {
      verify(() => mockCreateGoalUseCase(tGoal)).called(1);
    },
  );

  blocTest<GoalBloc, GoalState>(
    'DeleteGoalRequested should call deleteGoalUseCase',
    build: () {
      when(() => mockDeleteGoalUseCase('g1')).thenAnswer((_) async => const Right(null));
      return goalBloc;
    },
    act: (bloc) => bloc.add(const DeleteGoalRequested('g1')),
    verify: (_) {
      verify(() => mockDeleteGoalUseCase('g1')).called(1);
    },
  );
}
