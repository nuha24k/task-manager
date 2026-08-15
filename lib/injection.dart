import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/task_remote_data_source.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/usecases/task_usecases.dart';
import '../presentation/blocs/task_bloc.dart';

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

  // UseCases
  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => WatchTasksUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl()));
  sl.registerLazySingleton(() => ReorderTaskUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => TaskBloc(
      watchTasksUseCase: sl(),
      createTaskUseCase: sl(),
      reorderTaskUseCase: sl(),
      deleteTaskUseCase: sl(),
    ),
  );
}
