import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../../domain/entities/task.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks(String workspaceId);
  Stream<List<TaskModel>> watchTasks(String workspaceId);
  Future<TaskModel> createTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String taskId);
  Future<void> reorderTask({
    required String taskId,
    required TaskStatus newStatus,
    required int newPosition,
  });
  Stream<List<TaskCommentModel>> watchComments(String taskId);
  Future<void> addComment(TaskCommentModel comment);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final SupabaseClient supabaseClient;

  TaskRemoteDataSourceImpl(this.supabaseClient);

  // Mock initial tasks for fallback UI
  static final List<TaskModel> _mockTasks = [
    TaskModel(
      id: '00000000-0000-0000-0000-000000000001',
      workspaceId: '00000000-0000-0000-0000-000000000001',
      title: 'Website Design',
      description: 'Create website landing page & UI system',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      assigneeIds: const ['u1', 'u2', 'u3', 'u4'],
      dueDate: DateTime.now().add(const Duration(days: 5)),
      position: 0,
      progress: 0.65,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<TaskModel>> getTasks(String workspaceId) async {
    try {
      final response = await supabaseClient
          .from('tasks')
          .select()
          .eq('workspace_id', workspaceId)
          .order('position', ascending: true);

      return (response as List).map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Supabase getTasks Error: $e');
      return _mockTasks;
    }
  }

  @override
  Stream<List<TaskModel>> watchTasks(String workspaceId) {
    try {
      return supabaseClient
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('workspace_id', workspaceId)
          .map((maps) {
            final tasks = maps.map((map) => TaskModel.fromJson(map)).toList();
            tasks.sort((a, b) => a.position.compareTo(b.position));
            return tasks;
          });
    } catch (e) {
      debugPrint('Supabase watchTasks Stream Error: $e');
      return Stream.value(_mockTasks);
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final json = task.toJson();
      final user = supabaseClient.auth.currentUser;
      if (user != null) {
        json['created_by'] = user.id;
      }

      final response = await supabaseClient
          .from('tasks')
          .insert(json)
          .select()
          .single();

      return TaskModel.fromJson(response);
    } catch (e) {
      debugPrint('Supabase createTask Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      final json = task.toJson();
      await supabaseClient
          .from('tasks')
          .update(json)
          .eq('id', task.id);
    } catch (e) {
      debugPrint('Supabase updateTask Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await supabaseClient.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      debugPrint('Supabase deleteTask Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> reorderTask({
    required String taskId,
    required TaskStatus newStatus,
    required int newPosition,
  }) async {
    try {
      await supabaseClient.from('tasks').update({
        'status': newStatus.toDbValue(),
        'position': newPosition,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
    } catch (e) {
      debugPrint('Supabase reorderTask Error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<TaskCommentModel>> watchComments(String taskId) {
    try {
      return supabaseClient
          .from('task_comments')
          .stream(primaryKey: ['id'])
          .eq('task_id', taskId)
          .map((maps) => maps.map((map) => TaskCommentModel.fromJson(map)).toList());
    } catch (e) {
      debugPrint('Supabase watchComments Error: $e');
      return Stream.value([]);
    }
  }

  @override
  Future<void> addComment(TaskCommentModel comment) async {
    try {
      final json = comment.toJson();
      final user = supabaseClient.auth.currentUser;
      if (user != null) {
        json['user_id'] = user.id;
      }
      await supabaseClient.from('task_comments').insert(json);
    } catch (e) {
      debugPrint('Supabase addComment Error: $e');
      rethrow;
    }
  }
}
