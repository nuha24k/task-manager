import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:mocktail/mocktail.dart';
import 'package:task_management/domain/entities/task.dart';
import 'package:task_management/domain/usecases/chat_usecases.dart';
import 'package:task_management/presentation/blocs/chat_bloc.dart';

class MockWatchCommentsUseCase extends Mock implements WatchCommentsUseCase {}
class MockAddCommentUseCase extends Mock implements AddCommentUseCase {}

void main() {
  late ChatBloc chatBloc;
  late MockWatchCommentsUseCase mockWatchCommentsUseCase;
  late MockAddCommentUseCase mockAddCommentUseCase;

  final tComment = TaskComment(
    id: 'c1',
    taskId: 't1',
    userId: 'u1',
    content: 'Hello team!',
    createdAt: DateTime(2026, 8, 16),
  );

  setUpAll(() {
    registerFallbackValue(TaskComment(
      id: '',
      taskId: 't1',
      userId: 'u1',
      content: 'dummy',
      createdAt: DateTime.now(),
    ));
  });

  setUp(() {
    mockWatchCommentsUseCase = MockWatchCommentsUseCase();
    mockAddCommentUseCase = MockAddCommentUseCase();

    chatBloc = ChatBloc(
      watchCommentsUseCase: mockWatchCommentsUseCase,
      addCommentUseCase: mockAddCommentUseCase,
    );
  });

  tearDown(() {
    chatBloc.close();
  });

  test('initial state should be ChatInitial', () {
    expect(chatBloc.state, equals(ChatInitial()));
  });

  blocTest<ChatBloc, ChatState>(
    'WatchCommentsRequested should emit [ChatLoading, ChatLoaded] when stream emits comments',
    build: () {
      when(() => mockWatchCommentsUseCase('t1')).thenAnswer((_) => Stream.value([tComment]));
      return chatBloc;
    },
    act: (bloc) => bloc.add(const WatchCommentsRequested('t1')),
    expect: () => [
      ChatLoading(),
      ChatLoaded([tComment]),
    ],
    verify: (_) {
      verify(() => mockWatchCommentsUseCase('t1')).called(1);
    },
  );

  blocTest<ChatBloc, ChatState>(
    'SendCommentRequested should call addCommentUseCase',
    build: () {
      when(() => mockAddCommentUseCase(any())).thenAnswer((_) async => const Right(null));
      return chatBloc;
    },
    act: (bloc) => bloc.add(const SendCommentRequested(
      taskId: 't1',
      content: 'New message',
      userId: 'u1',
    )),
    verify: (_) {
      verify(() => mockAddCommentUseCase(any())).called(1);
    },
  );
}
