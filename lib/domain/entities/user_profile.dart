import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl];
}
