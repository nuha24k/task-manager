import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:mocktail/mocktail.dart';
import 'package:task_management/data/datasources/task_remote_data_source.dart';
import 'package:task_management/data/repositories/task_repository_impl.dart';

import '../../helpers/dummy_data.dart';

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

void main() {
  late MockTaskRemoteDataSource mockRemoteDataSource;
  late TaskRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockTaskRemoteDataSource();
    repository = TaskRepositoryImpl(remoteDataSource: mockRemoteDataSource);
    registerFallbackValue(tTaskModel);
  });

  group('getTasks', () {
    test('should return Right(List<Task>) when remote data source call is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.getTasks('ws1'))
          .thenAnswer((_) async => tTaskModels);

      // Act
      final result = await repository.getTasks('ws1');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not return left'),
        (r) => expect(r, equals(tTaskModels)),
      );
      verify(() => mockRemoteDataSource.getTasks('ws1')).called(1);
    });

    test('should return Left(Exception) when remote data source throws exception', () async {
      // Arrange
      when(() => mockRemoteDataSource.getTasks('ws1'))
          .thenThrow(Exception('Server error'));

      // Act
      final result = await repository.getTasks('ws1');

      // Assert
      expect(result.isLeft(), isTrue);
      verify(() => mockRemoteDataSource.getTasks('ws1')).called(1);
    });
  });

  group('createTask', () {
    test('should return Right(Task) when task creation is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.createTask(any()))
          .thenAnswer((_) async => tTaskModel);

      // Act
      final result = await repository.createTask(tTaskModel);

      // Assert
      expect(result, equals(Right(tTaskModel)));
      verify(() => mockRemoteDataSource.createTask(tTaskModel)).called(1);
    });

    test('should return Left(Exception) when remote data source fails to create task', () async {
      // Arrange
      when(() => mockRemoteDataSource.createTask(any()))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await repository.createTask(tTaskModel);

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });

  group('updateTask', () {
    test('should return Right(void) when task update is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.updateTask(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.updateTask(tTaskModel);

      // Assert
      expect(result, equals(const Right(null)));
      verify(() => mockRemoteDataSource.updateTask(tTaskModel)).called(1);
    });

    test('should return Left(Exception) when remote data source fails to update task', () async {
      // Arrange
      when(() => mockRemoteDataSource.updateTask(any()))
          .thenThrow(Exception('Update error'));

      // Act
      final result = await repository.updateTask(tTaskModel);

      // Assert
      expect(result.isLeft(), isTrue);
      verify(() => mockRemoteDataSource.updateTask(tTaskModel)).called(1);
    });
  });

  group('deleteTask', () {
    test('should return Right(void) when deletion is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.deleteTask('t1'))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.deleteTask('t1');

      // Assert
      expect(result, equals(const Right(null)));
      verify(() => mockRemoteDataSource.deleteTask('t1')).called(1);
    });
  });

  group('reorderTask', () {
    test('should return Right(void) when reorder is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.reorderTask(
            taskId: 't1',
            newStatus: TaskStatus.inProgress,
            newPosition: 2,
          )).thenAnswer((_) async => {});

      // Act
      final result = await repository.reorderTask(
        taskId: 't1',
        newStatus: TaskStatus.inProgress,
        newPosition: 2,
      );

      // Assert
      expect(result, equals(const Right(null)));
      verify(() => mockRemoteDataSource.reorderTask(
            taskId: 't1',
            newStatus: TaskStatus.inProgress,
            newPosition: 2,
          )).called(1);
    });
  });
}
