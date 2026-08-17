import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/data/models/task_invitation_model.dart';
import 'package:task_management/domain/entities/task_invitation.dart';

import '../../helpers/dummy_data.dart';

void main() {
  test('TaskInvitationModel should be a subclass of TaskInvitation entity', () {
    expect(tInvitationModel, isA<TaskInvitation>());
  });

  group('fromJson', () {
    test('should return a valid TaskInvitationModel when JSON contains all fields', () {
      // Arrange
      final jsonMap = {
        'id': 'inv1',
        'task_id': 't1',
        'inviter_id': 'u1',
        'token': 'tok123',
        'role': 'editor',
        'expires_at': '2026-08-17T00:00:00.000Z',
        'is_active': true,
        'created_at': '2026-08-16T00:00:00.000Z',
      };

      // Act
      final result = TaskInvitationModel.fromJson(jsonMap);

      // Assert
      expect(result, equals(tInvitationModel));
    });

    test('should return TaskInvitationModel with default values when optional JSON fields are missing/null', () {
      // Arrange
      final jsonMap = {
        'id': 'inv1',
        'task_id': 't1',
        'inviter_id': 'u1',
        'token': 'tok123',
        'role': null,
        'expires_at': null,
        'is_active': null,
        'created_at': '2026-08-16T00:00:00.000Z',
      };

      // Act
      final result = TaskInvitationModel.fromJson(jsonMap);

      // Assert
      expect(result.role, equals('editor'));
      expect(result.expiresAt, isNull);
      expect(result.isActive, isTrue);
    });
  });

  group('toJson', () {
    test('should return a JSON map containing proper key-values', () {
      // Act
      final result = tInvitationModel.toJson();

      // Assert
      final expectedJsonMap = {
        'id': 'inv1',
        'task_id': 't1',
        'inviter_id': 'u1',
        'token': 'tok123',
        'role': 'editor',
        'expires_at': '2026-08-17T00:00:00.000Z',
        'is_active': true,
        'created_at': '2026-08-16T00:00:00.000Z',
      };
      expect(result, equals(expectedJsonMap));
    });
  });

  group('isExpired property', () {
    test('should return false when expiresAt is null', () {
      final invitation = TaskInvitation(
        id: 'inv1',
        taskId: 't1',
        inviterId: 'u1',
        token: 'tok123',
        createdAt: DateTime.now(),
        expiresAt: null,
      );
      expect(invitation.isExpired, isFalse);
    });

    test('should return true when expiresAt is in the past', () {
      final invitation = TaskInvitation(
        id: 'inv1',
        taskId: 't1',
        inviterId: 'u1',
        token: 'tok123',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(invitation.isExpired, isTrue);
    });

    test('should return false when expiresAt is in the future', () {
      final invitation = TaskInvitation(
        id: 'inv1',
        taskId: 't1',
        inviterId: 'u1',
        token: 'tok123',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(invitation.isExpired, isFalse);
    });
  });
}
