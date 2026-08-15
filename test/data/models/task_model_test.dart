import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/data/models/task_model.dart';
import 'package:task_management/domain/entities/task.dart';

void main() {
  final tCreatedAt = DateTime.parse('2026-08-16T00:00:00.000Z');
  final tUpdatedAt = DateTime.parse('2026-08-16T01:00:00.000Z');
  final tDueDate = DateTime.parse('2026-08-20T00:00:00.000Z');

  final tTaskModel = TaskModel(
    id: 't1',
    workspaceId: 'ws1',
    title: 'Test Task',
    description: 'Test Description',
    status: TaskStatus.inProgress,
    priority: TaskPriority.high,
    assigneeIds: const ['u1', 'u2'],
    dueDate: tDueDate,
    position: 1,
    progress: 0.5,
    createdBy: 'u1',
    createdAt: tCreatedAt,
    updatedAt: tUpdatedAt,
  );

  final tJson = {
    'id': 't1',
    'workspace_id': 'ws1',
    'title': 'Test Task',
    'description': 'Test Description',
    'status': 'in_progress',
    'priority': 'high',
    'assignee_ids': ['u1', 'u2'],
    'due_date': '2026-08-20T00:00:00.000Z',
    'position': 1,
    'progress': 0.5,
    'created_by': 'u1',
    'created_at': '2026-08-16T00:00:00.000Z',
    'updated_at': '2026-08-16T01:00:00.000Z',
  };

  group('TaskModel', () {
    test('should be a subclass of Task entity', () {
      expect(tTaskModel, isA<Task>());
    });

    group('fromJson', () {
      test('should return a valid TaskModel when JSON contains all fields', () {
        // Act
        final result = TaskModel.fromJson(tJson);

        // Assert
        expect(result, equals(tTaskModel));
      });

      test('should return TaskModel with default values when optional JSON fields are null/missing', () {
        // Arrange
        final minimalJson = {
          'id': 't2',
          'workspace_id': 'ws1',
          'title': 'Minimal Task',
          'created_at': '2026-08-16T00:00:00.000Z',
          'updated_at': '2026-08-16T01:00:00.000Z',
        };

        // Act
        final result = TaskModel.fromJson(minimalJson);

        // Assert
        expect(result.id, equals('t2'));
        expect(result.status, equals(TaskStatus.todo));
        expect(result.priority, equals(TaskPriority.medium));
        expect(result.assigneeIds, isEmpty);
        expect(result.dueDate, isNull);
        expect(result.position, equals(0));
        expect(result.progress, equals(0.0));
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper key-values', () {
        // Act
        final result = tTaskModel.toJson();

        // Assert
        expect(result, equals(tJson));
      });
    });

    group('fromEntity', () {
      test('should return TaskModel identical to domain Task entity', () {
        // Arrange
        final entity = Task(
          id: 't1',
          workspaceId: 'ws1',
          title: 'Test Task',
          description: 'Test Description',
          status: TaskStatus.inProgress,
          priority: TaskPriority.high,
          assigneeIds: const ['u1', 'u2'],
          dueDate: tDueDate,
          position: 1,
          progress: 0.5,
          createdBy: 'u1',
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        // Act
        final result = TaskModel.fromEntity(entity);

        // Assert
        expect(result, equals(tTaskModel));
      });
    });
  });

  group('TaskStatus & TaskPriority Enums', () {
    test('should map db values to TaskStatus correctly', () {
      expect(TaskStatus.fromDbValue('todo'), equals(TaskStatus.todo));
      expect(TaskStatus.fromDbValue('in_progress'), equals(TaskStatus.inProgress));
      expect(TaskStatus.fromDbValue('done'), equals(TaskStatus.done));
      expect(TaskStatus.fromDbValue('unknown'), equals(TaskStatus.todo));
    });

    test('should convert TaskStatus to db string values correctly', () {
      expect(TaskStatus.todo.toDbValue(), equals('todo'));
      expect(TaskStatus.inProgress.toDbValue(), equals('in_progress'));
      expect(TaskStatus.done.toDbValue(), equals('done'));
    });

    test('should map db values to TaskPriority correctly', () {
      expect(TaskPriority.fromDbValue('low'), equals(TaskPriority.low));
      expect(TaskPriority.fromDbValue('medium'), equals(TaskPriority.medium));
      expect(TaskPriority.fromDbValue('high'), equals(TaskPriority.high));
      expect(TaskPriority.fromDbValue('unknown'), equals(TaskPriority.medium));
    });
  });
}
