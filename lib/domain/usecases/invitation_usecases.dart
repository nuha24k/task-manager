import 'package:fpdart/fpdart.dart';
import '../entities/task_invitation.dart';
import '../repositories/invitation_repository.dart';

class CreateInvitationUseCase {
  final InvitationRepository repository;

  CreateInvitationUseCase(this.repository);

  Future<Either<Exception, TaskInvitation>> call({
    required String taskId,
    String role = 'editor',
    DateTime? expiresAt,
  }) {
    return repository.createInvitation(
      taskId: taskId,
      role: role,
      expiresAt: expiresAt,
    );
  }
}

class GetInvitationByTokenUseCase {
  final InvitationRepository repository;

  GetInvitationByTokenUseCase(this.repository);

  Future<Either<Exception, TaskInvitation>> call(String token) {
    return repository.getInvitationByToken(token);
  }
}

class AcceptInvitationUseCase {
  final InvitationRepository repository;

  AcceptInvitationUseCase(this.repository);

  Future<Either<Exception, AcceptInvitationResult>> call(String token) {
    return repository.acceptInvitation(token);
  }
}

class RevokeInvitationUseCase {
  final InvitationRepository repository;

  RevokeInvitationUseCase(this.repository);

  Future<Either<Exception, void>> call(String invitationId) {
    return repository.revokeInvitation(invitationId);
  }
}
