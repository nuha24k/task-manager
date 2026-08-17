import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_invitation_model.dart';
import '../../domain/entities/task_invitation.dart';

abstract class InvitationRemoteDataSource {
  Future<TaskInvitationModel> createInvitation({
    required String taskId,
    required String inviterId,
    String role = 'editor',
    DateTime? expiresAt,
  });

  Future<TaskInvitationModel> getInvitationByToken(String token);

  Future<AcceptInvitationResult> acceptInvitation(String token);

  Future<void> revokeInvitation(String invitationId);
}

class InvitationRemoteDataSourceImpl implements InvitationRemoteDataSource {
  final SupabaseClient supabaseClient;

  InvitationRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<TaskInvitationModel> createInvitation({
    required String taskId,
    required String inviterId,
    String role = 'editor',
    DateTime? expiresAt,
  }) async {
    final response = await supabaseClient
        .from('project_invitations')
        .insert({
          'project_id': taskId,
          'inviter_id': inviterId,
          'role': role,
          'expires_at': expiresAt?.toIso8601String(),
          'is_active': true,
        })
        .select()
        .single();

    return TaskInvitationModel.fromJson(response);
  }

  @override
  Future<TaskInvitationModel> getInvitationByToken(String token) async {
    final response = await supabaseClient
        .from('project_invitations')
        .select()
        .eq('token', token)
        .eq('is_active', true)
        .single();

    return TaskInvitationModel.fromJson(response);
  }

  @override
  Future<AcceptInvitationResult> acceptInvitation(String token) async {
    final response = await supabaseClient.rpc(
      'accept_project_invitation',
      params: {'p_token': token},
    );

    if (response is List && response.isNotEmpty) {
      final item = Map<String, dynamic>.from(response.first as Map);
      return AcceptInvitationResult(
        success: item['success'] as bool? ?? false,
        message: item['message'] as String? ?? 'Unknown status',
        taskId: (item['project_id'] ?? item['task_id']) as String?,
      );
    } else if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      return AcceptInvitationResult(
        success: map['success'] as bool? ?? false,
        message: map['message'] as String? ?? 'Unknown status',
        taskId: (map['project_id'] ?? map['task_id']) as String?,
      );
    }

    return const AcceptInvitationResult(
      success: false,
      message: 'Failed to process invitation response',
    );
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    await supabaseClient
        .from('project_invitations')
        .update({'is_active': false})
        .eq('id', invitationId);
  }
}
