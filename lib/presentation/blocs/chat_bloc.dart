import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/chat_usecases.dart';

// --- Events ---
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class WatchCommentsRequested extends ChatEvent {
  final String taskId;
  const WatchCommentsRequested(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class SendCommentRequested extends ChatEvent {
  final String taskId;
  final String content;
  final String userId;

  const SendCommentRequested({
    required this.taskId,
    required this.content,
    required this.userId,
  });

  @override
  List<Object?> get props => [taskId, content, userId];
}

// --- States ---
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<TaskComment> comments;
  const ChatLoaded(this.comments);
  @override
  List<Object?> get props => [comments];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final WatchCommentsUseCase watchCommentsUseCase;
  final AddCommentUseCase addCommentUseCase;

  ChatBloc({
    required this.watchCommentsUseCase,
    required this.addCommentUseCase,
  }) : super(ChatInitial()) {
    on<WatchCommentsRequested>(_onWatchCommentsRequested);
    on<SendCommentRequested>(_onSendCommentRequested);
  }

  Future<void> _onWatchCommentsRequested(
    WatchCommentsRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      await emit.forEach<List<TaskComment>>(
        watchCommentsUseCase(event.taskId),
        onData: (comments) => ChatLoaded(comments),
        onError: (error, stackTrace) => ChatError(error.toString()),
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(ChatError(e.toString()));
      }
    }
  }

  Future<void> _onSendCommentRequested(
    SendCommentRequested event,
    Emitter<ChatState> emit,
  ) async {
    final comment = TaskComment(
      id: '',
      taskId: event.taskId,
      userId: event.userId,
      content: event.content,
      createdAt: DateTime.now(),
    );

    final result = await addCommentUseCase(comment);
    result.fold(
      (failure) {
        if (!emit.isDone) emit(ChatError(failure.toString()));
      },
      (_) {},
    );
  }
}
