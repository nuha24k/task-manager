import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/task_goal_model.dart';
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

  // Comments / Chat
  Stream<List<TaskCommentModel>> watchComments(String taskId);
  Future<void> addComment(TaskCommentModel comment);

  // Goals
  Stream<List<TaskGoalModel>> watchGoals(String taskId);
  Future<TaskGoalModel> createGoal(TaskGoalModel goal);
  Future<void> updateGoal(TaskGoalModel goal);
  Future<void> deleteGoal(String goalId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final SupabaseClient supabaseClient;
  final StreamController<List<TaskGoalModel>> _mockGoalsController = StreamController<List<TaskGoalModel>>.broadcast();

  TaskRemoteDataSourceImpl(this.supabaseClient);

  void _notifyMockGoalsChanged() {
    if (!_mockGoalsController.isClosed) {
      _mockGoalsController.add(List<TaskGoalModel>.from(_mockGoals));
    }
  }

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

  static final List<TaskGoalModel> _mockGoals = [
    TaskGoalModel(
      id: 'g1',
      taskId: '00000000-0000-0000-0000-000000000001',
      title: 'Design system',
      projectName: 'Charty App',
      priority: TaskPriority.high,
      isCompleted: true,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      createdAt: DateTime.now(),
    ),
    TaskGoalModel(
      id: 'g2',
      taskId: '00000000-0000-0000-0000-000000000001',
      title: 'Landing Page',
      projectName: 'Charty App',
      priority: TaskPriority.high,
      isCompleted: false,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      createdAt: DateTime.now(),
    ),
    TaskGoalModel(
      id: 'g3',
      taskId: '00000000-0000-0000-0000-000000000001',
      title: 'Pricing Page',
      projectName: 'Charty App',
      priority: TaskPriority.low,
      isCompleted: false,
      dueDate: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
    ),
    TaskGoalModel(
      id: 'g4',
      taskId: '00000000-0000-0000-0000-000000000001',
      title: 'Copywriting',
      projectName: 'Charty App',
      priority: TaskPriority.high,
      isCompleted: false,
      dueDate: DateTime.now().add(const Duration(days: 10)),
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<TaskModel>> getTasks(String workspaceId) async {
    try {
      final response = await supabaseClient
          .from('projects')
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
          .from('projects')
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
          .from('projects')
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
          .from('projects')
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
      await supabaseClient.from('projects').delete().eq('id', taskId);
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
      await supabaseClient.from('projects').update({
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
          .from('project_comments')
          .stream(primaryKey: ['id'])
          .eq('project_id', taskId)
          .order('created_at', ascending: true)
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
      json['project_id'] = comment.taskId;
      json.remove('task_id');
      await supabaseClient.from('project_comments').insert(json);
    } catch (e) {
      debugPrint('Supabase addComment Error: $e');
      rethrow;
    }
  }

  // --- Goals ---
  @override
  Stream<List<TaskGoalModel>> watchGoals(String taskId) async* {
    try {
      if (taskId.isNotEmpty) {
        yield* supabaseClient
            .from('project_goals')
            .stream(primaryKey: ['id'])
            .eq('project_id', taskId)
            .order('created_at', ascending: true)
            .map((maps) => maps.map((map) => TaskGoalModel.fromJson(map)).toList());
      } else {
        yield* supabaseClient
            .from('project_goals')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: true)
            .map((maps) => maps.map((map) => TaskGoalModel.fromJson(map)).toList());
      }
    } catch (e) {
      debugPrint('Supabase watchGoals Error: $e');
      final current = taskId.isNotEmpty
          ? _mockGoals.where((g) => g.taskId == taskId).toList()
          : List<TaskGoalModel>.from(_mockGoals);
      yield current;
      yield* _mockGoalsController.stream.map((list) {
        return taskId.isNotEmpty
            ? list.where((g) => g.taskId == taskId).toList()
            : List<TaskGoalModel>.from(list);
      });
    }
  }

  @override
  Future<TaskGoalModel> createGoal(TaskGoalModel goal) async {
    try {
      final json = goal.toJson();
      final response = await supabaseClient
          .from('project_goals')
          .insert(json)
          .select()
          .single();

      final created = TaskGoalModel.fromJson(response);
      _mockGoals.add(created);
      _notifyMockGoalsChanged();
      return created;
    } catch (e) {
      debugPrint('Supabase createGoal Error: $e');
      _mockGoals.add(goal);
      _notifyMockGoalsChanged();
      return goal;
    }
  }

  @override
  Future<void> updateGoal(TaskGoalModel goal) async {
    try {
      final json = goal.toJson();
      await supabaseClient
          .from('project_goals')
          .update(json)
          .eq('id', goal.id);
      final index = _mockGoals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _mockGoals[index] = goal;
      }
      _notifyMockGoalsChanged();
    } catch (e) {
      debugPrint('Supabase updateGoal Error: $e');
      final index = _mockGoals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _mockGoals[index] = goal;
      }
      _notifyMockGoalsChanged();
    }
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      await supabaseClient.from('project_goals').delete().eq('id', goalId);
      _mockGoals.removeWhere((g) => g.id == goalId);
      _notifyMockGoalsChanged();
    } catch (e) {
      debugPrint('Supabase deleteGoal Error: $e');
      _mockGoals.removeWhere((g) => g.id == goalId);
      _notifyMockGoalsChanged();
    }
  }
}
