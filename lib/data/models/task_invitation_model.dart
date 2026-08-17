import '../../domain/entities/task_invitation.dart';

class TaskInvitationModel extends TaskInvitation {
  const TaskInvitationModel({
    required super.id,
    required super.taskId,
    required super.inviterId,
    required super.token,
    super.role,
    super.expiresAt,
    super.isActive,
    required super.createdAt,
  });

  factory TaskInvitationModel.fromJson(Map<String, dynamic> json) {
    return TaskInvitationModel(
      id: json['id'] as String,
      taskId: (json['project_id'] ?? json['task_id']) as String,
      inviterId: json['inviter_id'] as String,
      token: json['token'] as String,
      role: json['role'] as String? ?? 'editor',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'project_id': taskId,
      'inviter_id': inviterId,
      'token': token,
      'role': role,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }
}
