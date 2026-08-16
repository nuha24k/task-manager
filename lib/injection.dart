import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/task_remote_data_source.dart';
import '../data/repositories/task_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/task_usecases.dart';
import '../domain/usecases/auth_usecases.dart';
import '../presentation/blocs/task_bloc.dart';
import '../presentation/blocs/auth_bloc.dart';

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

  // Repositories
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => WatchTasksUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl()));
  sl.registerLazySingleton(() => ReorderTaskUseCase(sl()));

  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));

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

  sl.registerLazySingleton(
    () => AuthBloc(
      getCurrentUserUseCase: sl(),
      signOutUseCase: sl(),
      watchAuthStateUseCase: sl(),
    ),
  );
}
