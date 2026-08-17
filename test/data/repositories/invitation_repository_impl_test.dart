import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_management/data/datasources/invitation_remote_datasource.dart';
import 'package:task_management/data/repositories/invitation_repository_impl.dart';

import '../../helpers/dummy_data.dart';

class MockInvitationRemoteDataSource extends Mock implements InvitationRemoteDataSource {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

void main() {
  late MockInvitationRemoteDataSource mockRemoteDataSource;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuthClient;
  late MockUser mockUser;
  late InvitationRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockInvitationRemoteDataSource();
    mockSupabaseClient = MockSupabaseClient();
    mockAuthClient = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuthClient);
    when(() => mockUser.id).thenReturn('u1');

    repository = InvitationRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      supabaseClient: mockSupabaseClient,
    );
  });

  group('createInvitation', () {
    test('should return Right(TaskInvitation) when authenticated and datasource call succeeds', () async {
      // Arrange
      when(() => mockAuthClient.currentUser).thenReturn(mockUser);
      when(() => mockRemoteDataSource.createInvitation(
            taskId: 't1',
            inviterId: 'u1',
            role: 'editor',
            expiresAt: null,
          )).thenAnswer((_) async => tInvitationModel);

      // Act
      final result = await repository.createInvitation(taskId: 't1', role: 'editor');

      // Assert
      expect(result, equals(Right(tInvitationModel)));
      verify(() => mockRemoteDataSource.createInvitation(
            taskId: 't1',
            inviterId: 'u1',
            role: 'editor',
            expiresAt: null,
          )).called(1);
    });

    test('should return Left(Exception) when user is not authenticated', () async {
      // Arrange
      when(() => mockAuthClient.currentUser).thenReturn(null);

      // Act
      final result = await repository.createInvitation(taskId: 't1', role: 'editor');

      // Assert
      expect(result.isLeft(), isTrue);
      verifyNever(() => mockRemoteDataSource.createInvitation(
            taskId: any(named: 'taskId'),
            inviterId: any(named: 'inviterId'),
            role: any(named: 'role'),
            expiresAt: any(named: 'expiresAt'),
          ));
    });

    test('should return Left(Exception) when remote datasource throws exception', () async {
      // Arrange
      when(() => mockAuthClient.currentUser).thenReturn(mockUser);
      when(() => mockRemoteDataSource.createInvitation(
            taskId: 't1',
            inviterId: 'u1',
            role: 'editor',
            expiresAt: null,
          )).thenThrow(Exception('DB Error'));

      // Act
      final result = await repository.createInvitation(taskId: 't1', role: 'editor');

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });

  group('getInvitationByToken', () {
    test('should return Right(TaskInvitation) when token is valid', () async {
      // Arrange
      when(() => mockRemoteDataSource.getInvitationByToken('tok123'))
          .thenAnswer((_) async => tInvitationModel);

      // Act
      final result = await repository.getInvitationByToken('tok123');

      // Assert
      expect(result, equals(Right(tInvitationModel)));
      verify(() => mockRemoteDataSource.getInvitationByToken('tok123')).called(1);
    });

    test('should return Left(Exception) when remote datasource throws exception', () async {
      // Arrange
      when(() => mockRemoteDataSource.getInvitationByToken('invalid'))
          .thenThrow(Exception('Token not found'));

      // Act
      final result = await repository.getInvitationByToken('invalid');

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });

  group('acceptInvitation', () {
    test('should return Right(AcceptInvitationResult) when accept call succeeds', () async {
      // Arrange
      when(() => mockRemoteDataSource.acceptInvitation('tok123'))
          .thenAnswer((_) async => tAcceptInvitationResult);

      // Act
      final result = await repository.acceptInvitation('tok123');

      // Assert
      expect(result, equals(const Right(tAcceptInvitationResult)));
      verify(() => mockRemoteDataSource.acceptInvitation('tok123')).called(1);
    });

    test('should return Left(Exception) when accept call throws exception', () async {
      // Arrange
      when(() => mockRemoteDataSource.acceptInvitation('tok123'))
          .thenThrow(Exception('RPC Error'));

      // Act
      final result = await repository.acceptInvitation('tok123');

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });

  group('revokeInvitation', () {
    test('should return Right(void) when revoke call succeeds', () async {
      // Arrange
      when(() => mockRemoteDataSource.revokeInvitation('inv1'))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.revokeInvitation('inv1');

      // Assert
      expect(result, equals(const Right(null)));
      verify(() => mockRemoteDataSource.revokeInvitation('inv1')).called(1);
    });

    test('should return Left(Exception) when revoke call fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.revokeInvitation('inv1'))
          .thenThrow(Exception('Revoke error'));

      // Act
      final result = await repository.revokeInvitation('inv1');

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });
}
