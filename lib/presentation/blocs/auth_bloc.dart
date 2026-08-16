import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/auth_usecases.dart';

// --- Events ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatusRequested extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

class AuthStateChangedInternal extends AuthEvent {
  final bool isAuthenticated;
  const AuthStateChangedInternal(this.isAuthenticated);
  @override
  List<Object?> get props => [isAuthenticated];
}

// --- States ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserProfile user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  final String? message;
  const Unauthenticated({this.message});
  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SignOutUseCase signOutUseCase;
  final WatchAuthStateUseCase watchAuthStateUseCase;

  StreamSubscription<bool>? _authStateSubscription;

  AuthBloc({
    required this.getCurrentUserUseCase,
    required this.signOutUseCase,
    required this.watchAuthStateUseCase,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusRequested>(_onCheckAuthStatusRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthStateChangedInternal>(_onAuthStateChangedInternal);

    _listenToAuthState();
  }

  void _listenToAuthState() {
    _authStateSubscription?.cancel();
    _authStateSubscription = watchAuthStateUseCase().listen((isAuthenticated) {
      add(AuthStateChangedInternal(isAuthenticated));
    });
  }

  Future<void> _onCheckAuthStatusRequested(
    CheckAuthStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await getCurrentUserUseCase();
    result.fold(
      (failure) => emit(Unauthenticated(message: failure.toString())),
      (userProfile) {
        if (userProfile != null) {
          emit(Authenticated(userProfile));
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  Future<void> _onAuthStateChangedInternal(
    AuthStateChangedInternal event,
    Emitter<AuthState> emit,
  ) async {
    if (!event.isAuthenticated) {
      emit(const Unauthenticated(message: 'Session expired. Please log in again.'));
    } else {
      final result = await getCurrentUserUseCase();
      result.fold(
        (failure) => emit(Unauthenticated(message: failure.toString())),
        (userProfile) {
          if (userProfile != null) {
            emit(Authenticated(userProfile));
          } else {
            emit(const Unauthenticated());
          }
        },
      );
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await signOutUseCase();
    emit(const Unauthenticated());
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
