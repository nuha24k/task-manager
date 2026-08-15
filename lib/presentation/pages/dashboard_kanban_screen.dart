import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../blocs/task_bloc.dart';
import '../theme/app_colors.dart';
import '../widgets/task_card.dart';
import '../widgets/floating_bottom_nav_bar.dart';
import '../widgets/create_task_bottom_sheet.dart';

class DashboardKanbanScreen extends StatefulWidget {
  final String workspaceId;

  const DashboardKanbanScreen({
    super.key,
    this.workspaceId = 'demo-workspace-id',
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
  }

  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateTaskBottomSheet(
        workspaceId: widget.workspaceId,
        onTaskCreated: (newTask) {
          context.read<TaskBloc>().add(CreateTaskRequested(newTask));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, state) {
                      if (state is TaskLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.blackButton),
                        );
                      }
                      if (state is TaskError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<TaskBloc>().add(SubscribeToBoard(widget.workspaceId));
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
                          context.read<TaskBloc>().add(SubscribeToBoard(widget.workspaceId));
                        },
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            const SizedBox(height: 12),
                            _buildHeroBanner(),
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
                                    style: TextStyle(color: AppColors.subText, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildKanbanView(tasks),
                            const SizedBox(height: 100), // Spacing for floating navbar
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNavBar(
                selectedIndex: _navIndex,
                onTap: (index) => setState(() => _navIndex = index),
                onAddPressed: _showCreateBottomSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=33'),
              ),
              SizedBox(width: 10),
              Text(
                'Esther Howard',
                style: TextStyle(
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
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.darkText),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.darkText),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7h 34 m',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your task almost done',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.access_time_filled_rounded, color: AppColors.darkText, size: 28),
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
        child: const Text('No tasks found. Tap + to add one!', style: TextStyle(color: AppColors.subText)),
      );
    }

    return Column(
      children: tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        final bgColor = index % 2 == 0 ? AppColors.secondaryCard : AppColors.primaryCard;
        
        return LongPressDraggable<Task>(
          data: task,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: TaskCard(task: task, backgroundColor: bgColor),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: TaskCard(task: task, backgroundColor: bgColor),
          ),
          child: DragTarget<Task>(
            onAcceptWithDetails: (details) {
              final draggedTask = details.data;
              if (draggedTask.id != task.id) {
                context.read<TaskBloc>().add(TaskMoved(
                      taskId: draggedTask.id,
                      newStatus: task.status,
                      newPosition: index,
                    ));
              }
            },
            builder: (context, candidateData, rejectedData) {
              return TaskCard(
                task: task,
                backgroundColor: bgColor,
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
