import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/domain/usecases/invitation_usecases.dart';
import 'package:task_management/presentation/blocs/invitation_bloc.dart';

import '../../helpers/dummy_data.dart';

class MockCreateInvitationUseCase extends Mock implements CreateInvitationUseCase {}
class MockGetInvitationByTokenUseCase extends Mock implements GetInvitationByTokenUseCase {}
class MockAcceptInvitationUseCase extends Mock implements AcceptInvitationUseCase {}
class MockRevokeInvitationUseCase extends Mock implements RevokeInvitationUseCase {}

void main() {
  late MockCreateInvitationUseCase mockCreateInvitationUseCase;
  late MockGetInvitationByTokenUseCase mockGetInvitationByTokenUseCase;
  late MockAcceptInvitationUseCase mockAcceptInvitationUseCase;
  late MockRevokeInvitationUseCase mockRevokeInvitationUseCase;
  late InvitationBloc invitationBloc;

  setUp(() {
    mockCreateInvitationUseCase = MockCreateInvitationUseCase();
    mockGetInvitationByTokenUseCase = MockGetInvitationByTokenUseCase();
    mockAcceptInvitationUseCase = MockAcceptInvitationUseCase();
    mockRevokeInvitationUseCase = MockRevokeInvitationUseCase();

    invitationBloc = InvitationBloc(
      createInvitationUseCase: mockCreateInvitationUseCase,
      getInvitationByTokenUseCase: mockGetInvitationByTokenUseCase,
      acceptInvitationUseCase: mockAcceptInvitationUseCase,
      revokeInvitationUseCase: mockRevokeInvitationUseCase,
    );
  });

  tearDown(() {
    invitationBloc.close();
  });

  test('initial state should be InvitationInitial', () {
    expect(invitationBloc.state, equals(InvitationInitial()));
  });

  group('CreateInvitationRequested', () {
    blocTest<InvitationBloc, InvitationState>(
      'should emit [InvitationLoading, InvitationCreatedState] when creation succeeds',
      build: () {
        when(() => mockCreateInvitationUseCase(
              taskId: 't1',
              role: 'editor',
              expiresAt: null,
            )).thenAnswer((_) async => Right(tInvitation));
        return invitationBloc;
      },
      act: (bloc) => bloc.add(const CreateInvitationRequested(taskId: 't1', role: 'editor')),
      expect: () => [
        InvitationLoading(),
        InvitationCreatedState(
          invitation: tInvitation,
          shareableUrl: 'https://taskflow.app/invite?token=tok123',
        ),
      ],
      verify: (_) {
        verify(() => mockCreateInvitationUseCase(
              taskId: 't1',
              role: 'editor',
              expiresAt: null,
            )).called(1);
      },
    );

    blocTest<InvitationBloc, InvitationState>(
      'should emit [InvitationLoading, InvitationErrorState] when creation fails',
      build: () {
        when(() => mockCreateInvitationUseCase(
              taskId: 't1',
              role: 'editor',
              expiresAt: null,
            )).thenAnswer((_) async => Left(Exception('Creation error')));
        return invitationBloc;
      },
      act: (bloc) => bloc.add(const CreateInvitationRequested(taskId: 't1', role: 'editor')),
      expect: () => [
        InvitationLoading(),
        isA<InvitationErrorState>(),
      ],
    );
  });

  group('GetInvitationDetailsRequested', () {
    blocTest<InvitationBloc, InvitationState>(
      'should emit [InvitationLoading, InvitationDetailsLoadedState] when fetch succeeds',
      build: () {
        when(() => mockGetInvitationByTokenUseCase('tok123'))
            .thenAnswer((_) async => Right(tInvitation));
        return invitationBloc;
      },
      act: (bloc) => bloc.add(const GetInvitationDetailsRequested(token: 'tok123')),
      expect: () => [
        InvitationLoading(),
        InvitationDetailsLoadedState(invitation: tInvitation),
      ],
    );

    blocTest<InvitationBloc, InvitationState>(
      'should emit [InvitationLoading, InvitationErrorState] when fetch fails',
      build: () {
        when(() => mockGetInvitationByTokenUseCase('invalid'))
            .thenAnswer((_) async => Left(Exception('Token error')));
        return invitationBloc;
      },
      act: (bloc) => bloc.add(const GetInvitationDetailsRequested(token: 'invalid')),
      expect: () => [
        InvitationLoading(),
        isA<InvitationErrorState>(),
      ],
    );
  });

  group('AcceptInvitationRequested', () {
    blocTest<InvitationBloc, InvitationState>(
      'should emit [InvitationLoading, InvitationAcceptedState] when accept succeeds',
      build: () {
        when(() => mockAcceptInvitationUseCase('tok123'))
            .thenAnswer((_) async => const Right(tAcceptInvitationResult));
        return invitationBloc;
      },
      act: (bloc) => bloc.add(const AcceptInvitationRequested(token: 'tok123')),
      expect: () => [
        InvitationLoading(),
        const InvitationAcceptedState(result: tAcceptInvitationResult),
      ],
    );

    blocTest<InvitationBloc, InvitationState>(
      'should emit [InvitationLoading, InvitationErrorState] when accept fails',
      build: () {
        when(() => mockAcceptInvitationUseCase('tok123'))
            .thenAnswer((_) async => Left(Exception('Accept error')));
        return invitationBloc;
      },
      act: (bloc) => bloc.add(const AcceptInvitationRequested(token: 'tok123')),
      expect: () => [
        InvitationLoading(),
        isA<InvitationErrorState>(),
      ],
    );
  });

  group('RevokeInvitationRequested', () {
    blocTest<InvitationBloc, InvitationState>(
      'should emit [InvitationLoading, InvitationRevokedState] when revoke succeeds',
      build: () {
        when(() => mockRevokeInvitationUseCase('inv1'))
            .thenAnswer((_) async => const Right(null));
        return invitationBloc;
      },
      act: (bloc) => bloc.add(const RevokeInvitationRequested(invitationId: 'inv1')),
      expect: () => [
        InvitationLoading(),
        InvitationRevokedState(),
      ],
    );

    blocTest<InvitationBloc, InvitationState>(
      'should emit [InvitationLoading, InvitationErrorState] when revoke fails',
      build: () {
        when(() => mockRevokeInvitationUseCase('inv1'))
            .thenAnswer((_) async => Left(Exception('Revoke error')));
        return invitationBloc;
      },
      act: (bloc) => bloc.add(const RevokeInvitationRequested(invitationId: 'inv1')),
      expect: () => [
        InvitationLoading(),
        isA<InvitationErrorState>(),
      ],
    );
  });

  group('ResetInvitationState', () {
    blocTest<InvitationBloc, InvitationState>(
      'should emit InvitationInitial when ResetInvitationState is added',
      build: () => invitationBloc,
      act: (bloc) => bloc.add(const ResetInvitationState()),
      expect: () => [
        InvitationInitial(),
      ],
    );
  });
}
