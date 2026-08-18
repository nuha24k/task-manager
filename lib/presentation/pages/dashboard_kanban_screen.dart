import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../blocs/task_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../widgets/task_card.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/create_task_bottom_sheet.dart';
import '../widgets/invitation_preview_dialog.dart';
import '../utils/deep_link_handler.dart';
import 'task_detail_screen.dart';

import 'calendar_meeting_screen.dart';
import 'statistics_screen.dart';
import 'user_profile_screen.dart';

class DashboardKanbanScreen extends StatefulWidget {
  final String workspaceId;

  const DashboardKanbanScreen({
    super.key,
    this.workspaceId = '00000000-0000-0000-0000-000000000001',
  });

  @override
  State<DashboardKanbanScreen> createState() => _DashboardKanbanScreenState();
}

class _DashboardKanbanScreenState extends State<DashboardKanbanScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(SubscribeToBoard(widget.workspaceId));
    context.read<AuthBloc>().add(CheckAuthStatusRequested());

    // Initialize DeepLinkHandler for invitation links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.init(
        onInvitationTokenReceived: (token) {
          InvitationPreviewDialog.show(
            context,
            token,
            onAccepted: () {
              context.read<TaskBloc>().add(
                SubscribeToBoard(widget.workspaceId),
              );
            },
          );
        },
      );
    });
  }

  @override
  void dispose() {
    DeepLinkHandler.dispose();
    super.dispose();
  }

  void _showCreateBottomSheet([Task? taskToEdit]) {
    final taskBloc = context.read<TaskBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: taskBloc,
        child: CreateTaskBottomSheet(
          workspaceId: widget.workspaceId,
          taskToEdit: taskToEdit,
          onTaskCreated: (task) {
            if (taskToEdit != null) {
              taskBloc.add(UpdateTaskRequested(task));
            } else {
              taskBloc.add(CreateTaskRequested(task));
            }
          },
        ),
      ),
    );
  }

  void _navigateToDetail(Task task) {
    final taskBloc = context.read<TaskBloc>();
    Navigator.push(
      context,
      _buildFadeSlideRoute(
        BlocProvider.value(value: taskBloc, child: TaskDetailScreen(task: task)),
      ),
    );
  }

  PageRouteBuilder _buildFadeSlideRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          if (state.message != null && state.message!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: Colors.red,
              ),
            );
          }
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(_navIndex),
                  child: _buildTab(_navIndex),
                ),
              ),
              // Floating Bottom Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingBottomNavBar(
                  selectedIndex: _navIndex,
                  onTap: (index) => setState(() => _navIndex = index),
                ),
              ),
              // FAB Positioned exactly above the Bottom Navigation Bar
              Positioned(
                right: 28,
                bottom: 80, // Positioned right above the bottom nav bar
                child: FloatingActionButton(
                  onPressed: () => _showCreateBottomSheet(),
                  backgroundColor: AppColors.blackButton,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 1:
        return const CalendarMeetingScreen();
      case 2:
        return const StatisticsScreen();
      case 3:
        return const UserProfileScreen();
      case 0:
      default:
        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.blackButton,
                      ),
                    );
                  }
                  if (state is TaskError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            child: Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.read<TaskBloc>().add(
                                SubscribeToBoard(widget.workspaceId),
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  List<Task> tasks = [];
                  if (state is TaskLoaded) {
                    tasks = state.tasks;
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TaskBloc>().add(
                        SubscribeToBoard(widget.workspaceId),
                      );
                    },
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 12),
                        _buildHeroBanner(tasks),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your task',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: AppColors.subText,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildKanbanView(tasks),
                        const SizedBox(
                          height: 140,
                        ), // Spacing for floating navbar & FAB
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
    }
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'Esther Howard';
        String avatarUrl = 'https://i.pravatar.cc/100?img=33';

        if (state is Authenticated) {
          userName = state.user.name;
          if (state.user.avatarUrl != null &&
              state.user.avatarUrl!.isNotEmpty) {
            avatarUrl = state.user.avatarUrl!;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.darkText,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.darkText,
                    ),
                    tooltip: 'Logout',
                    onPressed: () {
                      context.read<AuthBloc>().add(SignOutRequested());
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(List<Task> tasks) {
    final totalTasks = tasks.length;
    final completedTasks = tasks
        .where((t) => t.status == TaskStatus.done)
        .length;
    final inProgressTasks = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final todoTasks = tasks.where((t) => t.status == TaskStatus.todo).length;

    final double avgProgress = tasks.isEmpty
        ? 0.0
        : (tasks.fold<double>(0.0, (sum, t) => sum + t.progress) / totalTasks);
    final int progressPercent = (avgProgress * 100).round();

    String statText = totalTasks > 0
        ? '$progressPercent% Completed'
        : '0 Projects';
    String statSubtitle = totalTasks > 0
        ? '$completedTasks completed • $inProgressTasks in progress • $todoTasks to do'
        : 'Tap + to add your first project';

    if (completedTasks == totalTasks && totalTasks > 0) {
      statSubtitle = 'All $totalTasks projects completed! 🎉';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryCard,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mastering projects with\nmanagement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blackButton,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: AppColors.darkText,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanView(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text(
          'No tasks found. Tap + to add one!',
          style: TextStyle(color: AppColors.subText),
        ),
      );
    }

    return Column(
      children: tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        final bgColor = index % 2 == 0
            ? AppColors.secondaryCard
            : AppColors.primaryCard;

        return LongPressDraggable<Task>(
          data: task,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: TaskCard(
                task: task,
                backgroundColor: bgColor,
                onTap: () => _navigateToDetail(task),
                onEditTap: () => _showCreateBottomSheet(task),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: TaskCard(
              task: task,
              backgroundColor: bgColor,
              onTap: () => _navigateToDetail(task),
              onEditTap: () => _showCreateBottomSheet(task),
            ),
          ),
          child: DragTarget<Task>(
            onAcceptWithDetails: (details) {
              final draggedTask = details.data;
              if (draggedTask.id != task.id) {
                context.read<TaskBloc>().add(
                  TaskMoved(
                    taskId: draggedTask.id,
                    newStatus: task.status,
                    newPosition: index,
                  ),
                );
              }
            },
            builder: (context, candidateData, rejectedData) {
              return TaskCard(
                task: task,
                backgroundColor: bgColor,
                onTap: () => _navigateToDetail(task),
                onEditTap: () => _showCreateBottomSheet(task),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
