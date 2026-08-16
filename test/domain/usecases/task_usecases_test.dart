import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:mocktail/mocktail.dart';
import 'package:task_management/domain/repositories/task_repository.dart';
import 'package:task_management/domain/usecases/task_usecases.dart';

import '../../helpers/dummy_data.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late GetTasksUseCase getTasksUseCase;
  late CreateTaskUseCase createTaskUseCase;
  late UpdateTaskUseCase updateTaskUseCase;
  late ReorderTaskUseCase reorderTaskUseCase;
  late DeleteTaskUseCase deleteTaskUseCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    getTasksUseCase = GetTasksUseCase(mockRepository);
    createTaskUseCase = CreateTaskUseCase(mockRepository);
    updateTaskUseCase = UpdateTaskUseCase(mockRepository);
    reorderTaskUseCase = ReorderTaskUseCase(mockRepository);
    deleteTaskUseCase = DeleteTaskUseCase(mockRepository);
    registerFallbackValue(tTask);
  });

  group('GetTasksUseCase', () {
    test('should get tasks list from the repository when executed', () async {
      // Arrange
      when(() => mockRepository.getTasks('ws1'))
          .thenAnswer((_) async => Right([tTask]));

      // Act
      final result = await getTasksUseCase('ws1');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not be left'),
        (r) => expect(r, equals([tTask])),
      );
      verify(() => mockRepository.getTasks('ws1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('CreateTaskUseCase', () {
    test('should forward create task request to repository', () async {
      // Arrange
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) async => Right(tTask));

      // Act
      final result = await createTaskUseCase(tTask);

      // Assert
      expect(result, equals(Right(tTask)));
      verify(() => mockRepository.createTask(tTask)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('ReorderTaskUseCase', () {
    test('should forward reorder parameters to repository', () async {
      // Arrange
      when(() => mockRepository.reorderTask(
            taskId: 't1',
            newStatus: TaskStatus.done,
            newPosition: 3,
          )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await reorderTaskUseCase(
        taskId: 't1',
        newStatus: TaskStatus.done,
        newPosition: 3,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.reorderTask(
            taskId: 't1',
            newStatus: TaskStatus.done,
            newPosition: 3,
          )).called(1);
    });
  });

  group('UpdateTaskUseCase', () {
    test('should forward update task request to repository', () async {
      // Arrange
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await updateTaskUseCase(tTask);

      // Assert
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.updateTask(tTask)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('DeleteTaskUseCase', () {
    test('should forward delete task ID to repository', () async {
      // Arrange
      when(() => mockRepository.deleteTask('t1'))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await deleteTaskUseCase('t1');

      // Assert
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.deleteTask('t1')).called(1);
    });
  });
}
