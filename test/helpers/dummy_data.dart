import 'package:task_management/data/models/task_invitation_model.dart';
import 'package:task_management/data/models/task_model.dart';
import 'package:task_management/domain/entities/task.dart';
import 'package:task_management/domain/entities/task_invitation.dart';

export 'package:task_management/data/models/task_invitation_model.dart';
export 'package:task_management/data/models/task_model.dart';
export 'package:task_management/domain/entities/task.dart';
export 'package:task_management/domain/entities/task_invitation.dart';

final tCreatedAt = DateTime.parse('2026-08-16T00:00:00.000Z');
final tUpdatedAt = DateTime.parse('2026-08-16T01:00:00.000Z');

final tTask = Task(
  id: 't1',
  workspaceId: 'ws1',
  title: 'Test Task',
  status: TaskStatus.todo,
  priority: TaskPriority.high,
  position: 0,
  createdAt: tCreatedAt,
  updatedAt: tUpdatedAt,
);

final tTaskModel = TaskModel(
  id: 't1',
  workspaceId: 'ws1',
  title: 'Test Task',
  status: TaskStatus.todo,
  priority: TaskPriority.medium,
  position: 0,
  createdAt: tCreatedAt,
  updatedAt: tUpdatedAt,
);

final List<Task> tTasks = [tTask];
final List<TaskModel> tTaskModels = [tTaskModel];

final tInvitation = TaskInvitation(
  id: 'inv1',
  taskId: 't1',
  inviterId: 'u1',
  token: 'tok123',
  role: 'editor',
  expiresAt: DateTime.parse('2026-08-17T00:00:00.000Z'),
  isActive: true,
  createdAt: tCreatedAt,
);

final tInvitationModel = TaskInvitationModel(
  id: 'inv1',
  taskId: 't1',
  inviterId: 'u1',
  token: 'tok123',
  role: 'editor',
  expiresAt: DateTime.parse('2026-08-17T00:00:00.000Z'),
  isActive: true,
  createdAt: tCreatedAt,
);

const tAcceptInvitationResult = AcceptInvitationResult(
  success: true,
  message: 'Invitation accepted successfully',
  taskId: 't1',
);
