import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_management/domain/repositories/invitation_repository.dart';
import 'package:task_management/domain/usecases/invitation_usecases.dart';

import '../../helpers/dummy_data.dart';

class MockInvitationRepository extends Mock implements InvitationRepository {}

void main() {
  late MockInvitationRepository mockRepository;
  late CreateInvitationUseCase createInvitationUseCase;
  late GetInvitationByTokenUseCase getInvitationByTokenUseCase;
  late AcceptInvitationUseCase acceptInvitationUseCase;
  late RevokeInvitationUseCase revokeInvitationUseCase;

  setUp(() {
    mockRepository = MockInvitationRepository();
    createInvitationUseCase = CreateInvitationUseCase(mockRepository);
    getInvitationByTokenUseCase = GetInvitationByTokenUseCase(mockRepository);
    acceptInvitationUseCase = AcceptInvitationUseCase(mockRepository);
    revokeInvitationUseCase = RevokeInvitationUseCase(mockRepository);
  });

  group('CreateInvitationUseCase', () {
    test('should forward parameters to repository createInvitation', () async {
      // Arrange
      when(() => mockRepository.createInvitation(
            taskId: 't1',
            role: 'editor',
            expiresAt: null,
          )).thenAnswer((_) async => Right(tInvitation));

      // Act
      final result = await createInvitationUseCase(taskId: 't1', role: 'editor');

      // Assert
      expect(result, equals(Right(tInvitation)));
      verify(() => mockRepository.createInvitation(
            taskId: 't1',
            role: 'editor',
            expiresAt: null,
          )).called(1);
    });
  });

  group('GetInvitationByTokenUseCase', () {
    test('should get invitation by token from repository', () async {
      // Arrange
      when(() => mockRepository.getInvitationByToken('tok123'))
          .thenAnswer((_) async => Right(tInvitation));

      // Act
      final result = await getInvitationByTokenUseCase('tok123');

      // Assert
      expect(result, equals(Right(tInvitation)));
      verify(() => mockRepository.getInvitationByToken('tok123')).called(1);
    });
  });

  group('AcceptInvitationUseCase', () {
    test('should call acceptInvitation on repository with token', () async {
      // Arrange
      when(() => mockRepository.acceptInvitation('tok123'))
          .thenAnswer((_) async => const Right(tAcceptInvitationResult));

      // Act
      final result = await acceptInvitationUseCase('tok123');

      // Assert
      expect(result, equals(const Right(tAcceptInvitationResult)));
      verify(() => mockRepository.acceptInvitation('tok123')).called(1);
    });
  });

  group('RevokeInvitationUseCase', () {
    test('should call revokeInvitation on repository with invitationId', () async {
      // Arrange
      when(() => mockRepository.revokeInvitation('inv1'))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await revokeInvitationUseCase('inv1');

      // Assert
      expect(result, equals(const Right(null)));
      verify(() => mockRepository.revokeInvitation('inv1')).called(1);
    });
  });
}
