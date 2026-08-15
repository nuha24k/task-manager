# Coding Guidelines (Senior Flutter Developer)

## Rules & Standards

### 1. Naming Conventions
- Class names: `PascalCase` (e.g., `UserBloc`, `FetchProfileEvent`, `ProfileState`).
- Files and Directories: `snake_case` (e.g., `user_bloc.dart`, `fetch_profile_event.dart`).
- Variables and Methods: `camelCase` (e.g., `isLoading`, `fetchUserData()`).
- Constant Values: `lowerCamelCase` or `UPPER_SNAKE_CASE` for global values.

### 2. BLoC & Event Implementation Structure
```dart
// Event
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class FetchProfileRequested extends ProfileEvent {}

// State
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitialState extends ProfileState {}
class ProfileLoadingState extends ProfileState {}
class ProfileSuccessState extends ProfileState {
  final UserProfile profile;
  const ProfileSuccessState(this.profile);

  @override
  List<Object?> get props => [profile];
}
class ProfileFailureState extends ProfileState {
  final String errorMessage;
  const ProfileFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
```

### 3. Widget Guidelines
- Always mark constructors as `const` where possible.
- Extract complex UI fragments into dedicated private or public `StatelessWidget` widgets instead of monolithic helper methods (`_buildHeader()`).
- Prefer `BlocSelector` or `BlocBuilder` with `buildWhen` condition to prevent unnecessary UI rebuilds.
