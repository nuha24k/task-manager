import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task_invitation.dart';
import '../../domain/repositories/invitation_repository.dart';
import '../datasources/invitation_remote_datasource.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final InvitationRemoteDataSource remoteDataSource;
  final SupabaseClient supabaseClient;

  InvitationRepositoryImpl({
    required this.remoteDataSource,
    required this.supabaseClient,
  });

  @override
  Future<Either<Exception, TaskInvitation>> createInvitation({
    required String taskId,
    String role = 'editor',
    DateTime? expiresAt,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        return Left(Exception('User not authenticated'));
      }

      final invitation = await remoteDataSource.createInvitation(
        taskId: taskId,
        inviterId: currentUser.id,
        role: role,
        expiresAt: expiresAt,
      );
      return Right(invitation);
    } catch (e) {
      return Left(Exception('Failed to create invitation: $e'));
    }
  }

  @override
  Future<Either<Exception, TaskInvitation>> getInvitationByToken(String token) async {
    try {
      final invitation = await remoteDataSource.getInvitationByToken(token);
      return Right(invitation);
    } catch (e) {
      return Left(Exception('Invalid or expired invitation token: $e'));
    }
  }

  @override
  Future<Either<Exception, AcceptInvitationResult>> acceptInvitation(String token) async {
    try {
      final result = await remoteDataSource.acceptInvitation(token);
      return Right(result);
    } catch (e) {
      return Left(Exception('Failed to accept invitation: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> revokeInvitation(String invitationId) async {
    try {
      await remoteDataSource.revokeInvitation(invitationId);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to revoke invitation: $e'));
    }
  }
}
