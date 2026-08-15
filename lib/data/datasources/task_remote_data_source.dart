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

  @override
  Future<List<TaskModel>> getTasks(String workspaceId) async {
    final response = await supabaseClient
        .from('tasks')
        .select()
        .eq('workspace_id', workspaceId)
        .order('position', ascending: true);

    return (response as List).map((json) => TaskModel.fromJson(json)).toList();
  }

  @override
  Stream<List<TaskModel>> watchTasks(String workspaceId) {
    return supabaseClient
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('workspace_id', workspaceId)
        .map((maps) {
          final tasks = maps.map((map) => TaskModel.fromJson(map)).toList();
          tasks.sort((a, b) => a.position.compareTo(b.position));
          return tasks;
        });
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    final json = task.toJson();
    if (task.id.isEmpty) {
      json.remove('id');
    }
    final response = await supabaseClient
        .from('tasks')
        .insert(json)
        .select()
        .single();
    return TaskModel.fromJson(response);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await supabaseClient
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await supabaseClient.from('tasks').delete().eq('id', taskId);
  }

  @override
  Future<void> reorderTask({
    required String taskId,
    required TaskStatus newStatus,
    required int newPosition,
  }) async {
    await supabaseClient.from('tasks').update({
      'status': newStatus.toDbValue(),
      'position': newPosition,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', taskId);
  }

  @override
  Stream<List<TaskCommentModel>> watchComments(String taskId) {
    return supabaseClient
        .from('task_comments')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .map((maps) => maps.map((map) => TaskCommentModel.fromJson(map)).toList());
  }

  @override
  Future<void> addComment(TaskCommentModel comment) async {
    final json = comment.toJson();
    if (comment.id.isEmpty) {
      json.remove('id');
    }
    await supabaseClient.from('task_comments').insert(json);
  }
}
