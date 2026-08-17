import 'package:fpdart/fpdart.dart';
import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;
  GetCurrentUserUseCase(this.repository);

  Future<Either<Exception, UserProfile?>> call() {
    return repository.getCurrentUser();
  }
}

class SignOutUseCase {
  final AuthRepository repository;
  SignOutUseCase(this.repository);

  Future<Either<Exception, void>> call() {
    return repository.signOut();
  }
}

class WatchAuthStateUseCase {
  final AuthRepository repository;
  WatchAuthStateUseCase(this.repository);

  Stream<bool> call() {
    return repository.watchAuthState();
  }
}
