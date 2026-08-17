import 'package:fpdart/fpdart.dart';
import '../entities/task_invitation.dart';

abstract class InvitationRepository {
  Future<Either<Exception, TaskInvitation>> createInvitation({
    required String taskId,
    String role = 'editor',
    DateTime? expiresAt,
  });

  Future<Either<Exception, TaskInvitation>> getInvitationByToken(String token);

  Future<Either<Exception, AcceptInvitationResult>> acceptInvitation(String token);

  Future<Either<Exception, void>> revokeInvitation(String invitationId);
}
