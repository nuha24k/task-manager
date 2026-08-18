import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_goal.dart';
import '../blocs/task_bloc.dart';
import '../blocs/goal_bloc.dart';
import '../theme/app_colors.dart';
import '../../injection.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GoalBloc>(
      create: (_) => sl<GoalBloc>()..add(const WatchGoalsRequested('')),
      child: const _StatisticsView(),
    );
  }
}

class _StatisticsView extends StatefulWidget {
  const _StatisticsView();

  @override
  State<_StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<_StatisticsView> {
  int _selectedPeriod = 0; // 0: Week, 1: Month, 2: Year

  // The `progress` column on `projects` is never updated by the app (stays
  // at its 0.0 default), so derive real progress from goal completion —
  // this is the actual live data the stats should reflect.
  double _taskProgress(Task task, List<TaskGoal> allGoals) {
    final goalsForTask = allGoals.where((g) => g.taskId == task.id).toList();
    if (goalsForTask.isEmpty) return task.progress;
    final completed = goalsForTask.where((g) => g.isCompleted).length;
    return completed / goalsForTask.length;
  }

  bool _isInPeriod(DateTime? date, DateTime now) {
    if (date == null) return false;
    final local = date.toLocal();
    if (_selectedPeriod == 0) {
      // Current Week (Monday to Sunday)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final start = DateTime(monday.year, monday.month, monday.day);
      final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
      return local.isAfter(start.subtract(const Duration(seconds: 1))) && local.isBefore(end);
    } else if (_selectedPeriod == 1) {
      // Current Month
      return local.year == now.year && local.month == now.month;
    } else {
      // Current Year
      return local.year == now.year;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, taskState) {
            List<Task> allTasks = [];
            if (taskState is TaskLoaded) {
              allTasks = taskState.tasks;
            }

            return BlocBuilder<GoalBloc, GoalState>(
              builder: (context, goalState) {
                List<TaskGoal> allGoals = [];
                if (goalState is GoalLoaded) {
                  allGoals = goalState.goals;
                }

                // Filter items according to selected period
                final periodTasks = allTasks.where((t) {
                  final target = t.dueDate ?? t.createdAt;
                  return _isInPeriod(target, now);
                }).toList();
                
                final tasksToDisplay = periodTasks.isNotEmpty ? periodTasks : allTasks;

                final periodGoals = allGoals.where((g) {
                  final target = g.dueDate ?? g.createdAt;
                  return _isInPeriod(target, now);
                }).toList();

                // Productivity metrics
                final totalTasksCount = tasksToDisplay.length;
                final completedCount = tasksToDisplay.where((t) => t.status == TaskStatus.done).length;
                final inProgressCount = tasksToDisplay.where((t) => t.status == TaskStatus.inProgress).length;
                final todoCount = tasksToDisplay.where((t) => t.status == TaskStatus.todo).length;
                final pendingCount = inProgressCount + todoCount;

                final double avgProgress = tasksToDisplay.isEmpty
                    ? 0.0
                    : (tasksToDisplay.fold<double>(0.0, (sum, t) => sum + _taskProgress(t, allGoals)) / totalTasksCount);
                final productivityRatePercent = (avgProgress * 100).toStringAsFixed(1);

                // Weekday productivity for bar chart (1 = Mon ... 7 = Sun).
                // Only count items that are DONE *and* whose date has
                // actually occurred — a task due Friday but marked done
                // today (Monday) is not "Friday activity", and a day that
                // hasn't happened yet can never show a tall bar.
                final weekdayCounts = List.generate(7, (index) {
                  final weekday = index + 1;
                  final taskMatch = tasksToDisplay.where((t) {
                    if (t.status != TaskStatus.done) return false;
                    final date = (t.dueDate ?? t.createdAt).toLocal();
                    return date.weekday == weekday && !date.isAfter(now);
                  }).length;
                  final goalMatch = periodGoals.where((g) {
                    if (!g.isCompleted) return false;
                    final date = (g.dueDate ?? g.createdAt).toLocal();
                    return date.weekday == weekday && !date.isAfter(now);
                  }).length;
                  return taskMatch + goalMatch;
                });

                final maxCount = weekdayCounts.fold<int>(1, (prev, curr) => max(prev, curr));

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Analytics & Stats',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedPeriod,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.darkText),
                                items: const [
                                  DropdownMenuItem(value: 0, child: Text('This Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 1, child: Text('This Month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 2, child: Text('This Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPeriod = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Hero Productivity Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCard,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Productivity Rate',
                                  style: TextStyle(fontSize: 14, color: AppColors.subText, fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryCard,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.darkText),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+$productivityRatePercent%',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkText),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$productivityRatePercent%',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Custom Bar Chart Representation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBar('Mon', weekdayCounts[0] == 0 ? 0.15 : (weekdayCounts[0] / maxCount), now.weekday == 1),
                                _buildBar('Tue', weekdayCounts[1] == 0 ? 0.15 : (weekdayCounts[1] / maxCount), now.weekday == 2),
                                _buildBar('Wed', weekdayCounts[2] == 0 ? 0.15 : (weekdayCounts[2] / maxCount), now.weekday == 3),
                                _buildBar('Thu', weekdayCounts[3] == 0 ? 0.15 : (weekdayCounts[3] / maxCount), now.weekday == 4),
                                _buildBar('Fri', weekdayCounts[4] == 0 ? 0.15 : (weekdayCounts[4] / maxCount), now.weekday == 5),
                                _buildBar('Sat', weekdayCounts[5] == 0 ? 0.15 : (weekdayCounts[5] / maxCount), now.weekday == 6),
                                _buildBar('Sun', weekdayCounts[6] == 0 ? 0.15 : (weekdayCounts[6] / maxCount), now.weekday == 7),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Overview Grid Cards (Completed / In Progress)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryCard,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.darkText),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('Completed Tasks', style: TextStyle(fontSize: 12, color: AppColors.subText)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedCount Tasks',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentYellow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.hourglass_top_rounded, size: 20, color: AppColors.darkText),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('Pending Tasks', style: TextStyle(fontSize: 12, color: AppColors.subText)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$pendingCount Tasks',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Task Distribution Section
                      const Text(
                        'Task Distribution',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                      ),
                      const SizedBox(height: 12),

                      if (tasksToDisplay.isNotEmpty)
                        ...tasksToDisplay.map((task) {
                          final taskGoalsCount = allGoals.where((g) => g.taskId == task.id).length;
                          Color accentColor = AppColors.priorityMedium;
                          if (task.priority == TaskPriority.high) accentColor = AppColors.priorityHigh;
                          if (task.priority == TaskPriority.low) accentColor = AppColors.priorityLow;

                          final subtitleText = taskGoalsCount > 0 ? '$taskGoalsCount Goal(s)' : '1 Task';
                          return _buildDistributionTile(
                            task.title,
                            subtitleText,
                            _taskProgress(task, allGoals),
                            accentColor,
                          );
                        })
                      else
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'No project data available. Add tasks to see analytics!',
                            style: TextStyle(color: AppColors.subText),
                          ),
                        ),

                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBar(String day, double heightRatio, bool isHighlighted) {
    final clampedRatio = heightRatio.clamp(0.15, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 24,
          height: 100 * clampedRatio,
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.blackButton : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? AppColors.darkText : AppColors.subText,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionTile(String title, String count, double progress, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
              ),
              const SizedBox(width: 8),
              Text(count, style: const TextStyle(fontSize: 12, color: AppColors.subText, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.chipBackground,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
