import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabaseClient;

  AuthRepositoryImpl(this.supabaseClient);

  @override
  Future<Either<Exception, UserProfile?>> getCurrentUser() async {
    try {
      final user = supabaseClient.auth.currentUser;
      if (user == null) {
        return const Right(null);
      }

      final metadata = user.userMetadata;
      final name = (metadata?['full_name'] as String?) ??
          user.email?.split('@').first ??
          'User';
      final avatarUrl = (metadata?['avatar_url'] as String?) ??
          'https://i.pravatar.cc/100?img=33';

      final userProfile = UserProfile(
        id: user.id,
        email: user.email ?? '',
        name: name,
        avatarUrl: avatarUrl,
      );

      return Right(userProfile);
    } catch (e) {
      return Left(Exception('Failed to fetch user profile: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> signOut() async {
    try {
      await supabaseClient.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to sign out: $e'));
    }
  }

  @override
  Stream<bool> watchAuthState() {
    return supabaseClient.auth.onAuthStateChange.map((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut ||
          (event == AuthChangeEvent.tokenRefreshed && data.session == null)) {
        return false;
      }
      return data.session != null;
    });
  }
}
