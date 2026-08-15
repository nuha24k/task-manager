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

  // Mock initial tasks for UI demo mode when Supabase is not initialized
  static final List<TaskModel> _mockTasks = [
    TaskModel(
      id: '1',
      workspaceId: 'demo-workspace-id',
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
    TaskModel(
      id: '2',
      workspaceId: 'demo-workspace-id',
      title: 'Mobile App Redesign',
      description: 'Update color palette and components',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      assigneeIds: const ['u1', 'u2'],
      dueDate: DateTime.now().add(const Duration(days: 10)),
      position: 1,
      progress: 0.30,
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
    } catch (_) {
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
    } catch (_) {
      return Stream.value(_mockTasks);
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
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
    } catch (_) {
      final mock = TaskModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workspaceId: task.workspaceId,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        position: _mockTasks.length,
        progress: 0.1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _mockTasks.add(mock);
      return mock;
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await supabaseClient
          .from('tasks')
          .update(task.toJson())
          .eq('id', task.id);
    } catch (_) {}
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await supabaseClient.from('tasks').delete().eq('id', taskId);
    } catch (_) {
      _mockTasks.removeWhere((t) => t.id == taskId);
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
    } catch (_) {
      final index = _mockTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _mockTasks[index] = TaskModel.fromEntity(
          _mockTasks[index].copyWith(status: newStatus, position: newPosition),
        );
      }
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
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<void> addComment(TaskCommentModel comment) async {
    try {
      final json = comment.toJson();
      if (comment.id.isEmpty) {
        json.remove('id');
      }
      await supabaseClient.from('task_comments').insert(json);
    } catch (_) {}
  }
}
