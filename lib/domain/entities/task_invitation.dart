import 'package:equatable/equatable.dart';

class TaskInvitation extends Equatable {
  final String id;
  final String taskId;
  final String inviterId;
  final String token;
  final String role;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;

  const TaskInvitation({
    required this.id,
    required this.taskId,
    required this.inviterId,
    required this.token,
    this.role = 'editor',
    this.expiresAt,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        inviterId,
        token,
        role,
        expiresAt,
        isActive,
        createdAt,
      ];
}

class AcceptInvitationResult extends Equatable {
  final bool success;
  final String message;
  final String? taskId;

  const AcceptInvitationResult({
    required this.success,
    required this.message,
    this.taskId,
  });

  @override
  List<Object?> get props => [success, message, taskId];
}
