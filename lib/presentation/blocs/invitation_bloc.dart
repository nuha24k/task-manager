import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_invitation.dart';
import '../../domain/usecases/invitation_usecases.dart';

// ==========================================
// EVENTS
// ==========================================
abstract class InvitationEvent extends Equatable {
  const InvitationEvent();

  @override
  List<Object?> get props => [];
}

class CreateInvitationRequested extends InvitationEvent {
  final String taskId;
  final String role;
  final DateTime? expiresAt;

  const CreateInvitationRequested({
    required this.taskId,
    this.role = 'editor',
    this.expiresAt,
  });

  @override
  List<Object?> get props => [taskId, role, expiresAt];
}

class GetInvitationDetailsRequested extends InvitationEvent {
  final String token;

  const GetInvitationDetailsRequested({required this.token});

  @override
  List<Object?> get props => [token];
}

class AcceptInvitationRequested extends InvitationEvent {
  final String token;

  const AcceptInvitationRequested({required this.token});

  @override
  List<Object?> get props => [token];
}

class RevokeInvitationRequested extends InvitationEvent {
  final String invitationId;

  const RevokeInvitationRequested({required this.invitationId});

  @override
  List<Object?> get props => [invitationId];
}

class ResetInvitationState extends InvitationEvent {
  const ResetInvitationState();
}

// ==========================================
// STATES
// ==========================================
abstract class InvitationState extends Equatable {
  const InvitationState();

  @override
  List<Object?> get props => [];
}

class InvitationInitial extends InvitationState {}

class InvitationLoading extends InvitationState {}

class InvitationCreatedState extends InvitationState {
  final TaskInvitation invitation;
  final String shareableUrl;

  const InvitationCreatedState({
    required this.invitation,
    required this.shareableUrl,
  });

  @override
  List<Object?> get props => [invitation, shareableUrl];
}

class InvitationDetailsLoadedState extends InvitationState {
  final TaskInvitation invitation;

  const InvitationDetailsLoadedState({required this.invitation});

  @override
  List<Object?> get props => [invitation];
}

class InvitationAcceptedState extends InvitationState {
  final AcceptInvitationResult result;

  const InvitationAcceptedState({required this.result});

  @override
  List<Object?> get props => [result];
}

class InvitationRevokedState extends InvitationState {}

class InvitationErrorState extends InvitationState {
  final String message;

  const InvitationErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==========================================
// BLOC IMPLEMENTATION
// ==========================================
class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  final CreateInvitationUseCase createInvitationUseCase;
  final GetInvitationByTokenUseCase getInvitationByTokenUseCase;
  final AcceptInvitationUseCase acceptInvitationUseCase;
  final RevokeInvitationUseCase revokeInvitationUseCase;

  static const String baseDomain = 'https://taskflow.app/invite';

  InvitationBloc({
    required this.createInvitationUseCase,
    required this.getInvitationByTokenUseCase,
    required this.acceptInvitationUseCase,
    required this.revokeInvitationUseCase,
  }) : super(InvitationInitial()) {
    on<CreateInvitationRequested>(_onCreateInvitation);
    on<GetInvitationDetailsRequested>(_onGetInvitationDetails);
    on<AcceptInvitationRequested>(_onAcceptInvitation);
    on<RevokeInvitationRequested>(_onRevokeInvitation);
    on<ResetInvitationState>((event, emit) => emit(InvitationInitial()));
  }

  Future<void> _onCreateInvitation(
    CreateInvitationRequested event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await createInvitationUseCase(
      taskId: event.taskId,
      role: event.role,
      expiresAt: event.expiresAt,
    );

    result.fold(
      (failure) => emit(InvitationErrorState(message: failure.toString())),
      (invitation) {
        final shareUrl = '$baseDomain?token=${invitation.token}';
        emit(InvitationCreatedState(
          invitation: invitation,
          shareableUrl: shareUrl,
        ));
      },
    );
  }

  Future<void> _onGetInvitationDetails(
    GetInvitationDetailsRequested event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await getInvitationByTokenUseCase(event.token);

    result.fold(
      (failure) => emit(InvitationErrorState(message: failure.toString())),
      (invitation) => emit(InvitationDetailsLoadedState(invitation: invitation)),
    );
  }

  Future<void> _onAcceptInvitation(
    AcceptInvitationRequested event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await acceptInvitationUseCase(event.token);

    result.fold(
      (failure) => emit(InvitationErrorState(message: failure.toString())),
      (acceptResult) => emit(InvitationAcceptedState(result: acceptResult)),
    );
  }

  Future<void> _onRevokeInvitation(
    RevokeInvitationRequested event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await revokeInvitationUseCase(event.invitationId);

    result.fold(
      (failure) => emit(InvitationErrorState(message: failure.toString())),
      (_) => emit(InvitationRevokedState()),
    );
  }
}
