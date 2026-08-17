import 'package:fpdart/fpdart.dart';
import '../entities/user_profile.dart';

abstract class AuthRepository {
  Future<Either<Exception, UserProfile?>> getCurrentUser();
  Future<Either<Exception, void>> signOut();
  Stream<bool> watchAuthState();
}
