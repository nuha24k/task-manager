import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/task_remote_data_source.dart';
import '../data/datasources/invitation_remote_datasource.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/invitation_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/invitation_repository.dart';
import '../domain/usecases/task_usecases.dart';
import '../domain/usecases/auth_usecases.dart';
import '../domain/usecases/goal_usecases.dart';
import '../domain/usecases/chat_usecases.dart';
import '../domain/usecases/invitation_usecases.dart';
import '../presentation/blocs/task_bloc.dart';
import '../presentation/blocs/auth_bloc.dart';
import '../presentation/blocs/goal_bloc.dart';
import '../presentation/blocs/chat_bloc.dart';
import '../presentation/blocs/invitation_bloc.dart';

final sl = GetIt.instance;


Future<void> initInjection({SupabaseClient? supabaseClient}) async {
  // External
  sl.registerLazySingleton<SupabaseClient>(
    () => supabaseClient ?? Supabase.instance.client,
  );

  // Data Sources
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<InvitationRemoteDataSource>(
    () => InvitationRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<InvitationRepository>(
    () => InvitationRepositoryImpl(
      remoteDataSource: sl(),
      supabaseClient: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => WatchTasksUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl()));
  sl.registerLazySingleton(() => ReorderTaskUseCase(sl()));

  sl.registerLazySingleton(() => WatchGoalsUseCase(sl()));
  sl.registerLazySingleton(() => CreateGoalUseCase(sl()));
  sl.registerLazySingleton(() => UpdateGoalUseCase(sl()));
  sl.registerLazySingleton(() => DeleteGoalUseCase(sl()));

  sl.registerLazySingleton(() => WatchCommentsUseCase(sl()));
  sl.registerLazySingleton(() => AddCommentUseCase(sl()));

  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));

  sl.registerLazySingleton(() => CreateInvitationUseCase(sl()));
  sl.registerLazySingleton(() => GetInvitationByTokenUseCase(sl()));
  sl.registerLazySingleton(() => AcceptInvitationUseCase(sl()));
  sl.registerLazySingleton(() => RevokeInvitationUseCase(sl()));


  // BLoCs
  sl.registerFactory(
    () => TaskBloc(
      watchTasksUseCase: sl(),
      createTaskUseCase: sl(),
      updateTaskUseCase: sl(),
      reorderTaskUseCase: sl(),
      deleteTaskUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => GoalBloc(
      watchGoalsUseCase: sl(),
      createGoalUseCase: sl(),
      updateGoalUseCase: sl(),
      deleteGoalUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ChatBloc(
      watchCommentsUseCase: sl(),
      addCommentUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => AuthBloc(
      getCurrentUserUseCase: sl(),
      signOutUseCase: sl(),
      watchAuthStateUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => InvitationBloc(
      createInvitationUseCase: sl(),
      getInvitationByTokenUseCase: sl(),
      acceptInvitationUseCase: sl(),
      revokeInvitationUseCase: sl(),
    ),
  );
}

