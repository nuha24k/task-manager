import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_goal.dart';
import '../blocs/goal_bloc.dart';
import '../blocs/task_bloc.dart';
import '../theme/app_colors.dart';
import '../../injection.dart';
import 'task_detail_screen.dart';

class CalendarMeetingScreen extends StatelessWidget {
  const CalendarMeetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GoalBloc>(
      create: (_) => sl<GoalBloc>()..add(const WatchGoalsRequested('')),
      child: const _CalendarMeetingView(),
    );
  }
}

class _CalendarMeetingView extends StatefulWidget {
  const _CalendarMeetingView();

  @override
  State<_CalendarMeetingView> createState() => _CalendarMeetingViewState();
}

class _CalendarMeetingViewState extends State<_CalendarMeetingView> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _resetToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year && localA.month == localB.month && localA.day == localB.day;
  }

  void _navigateToTaskDetail(BuildContext context, TaskGoal goal) {
    Task? targetTask;

    try {
      final taskState = context.read<TaskBloc>().state;
      if (taskState is TaskLoaded) {
        final found = taskState.tasks.where((t) => t.id == goal.taskId);
        if (found.isNotEmpty) {
          targetTask = found.first;
        }
      }
    } catch (_) {}

    targetTask ??= Task(
      id: goal.taskId.isNotEmpty ? goal.taskId : '00000000-0000-0000-0000-000000000001',
      workspaceId: '00000000-0000-0000-0000-000000000001',
      title: goal.projectName.isNotEmpty ? goal.projectName : goal.title,
      description: 'Task containing goal: ${goal.title}',
      status: goal.isCompleted ? TaskStatus.done : TaskStatus.inProgress,
      priority: goal.priority,
      dueDate: goal.dueDate,
      position: 0,
      progress: goal.isCompleted ? 1.0 : 0.5,
      createdAt: goal.createdAt,
      updatedAt: DateTime.now(),
    );

    TaskBloc? taskBloc;
    try {
      taskBloc = context.read<TaskBloc>();
    } catch (_) {}

    if (taskBloc != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: taskBloc!,
            child: TaskDetailScreen(task: targetTask!),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(task: targetTask!),
        ),
      );
    }
  }

  void _showCreateGoalModal(BuildContext context) {
    GoalBloc? goalBloc;
    try {
      goalBloc = context.read<GoalBloc>();
    } catch (_) {}

    TaskBloc? taskBloc;
    try {
      taskBloc = context.read<TaskBloc>();
    } catch (_) {}

    final titleController = TextEditingController();
    final projectController = TextEditingController();
    TaskPriority priority = TaskPriority.medium;
    DateTime goalDueDate = _selectedDate;
    Task? selectedTask;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        Widget content = StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Goal / Task',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Goal Title',
                    filled: true,
                    fillColor: AppColors.chipBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, taskState) {
                    List<Task> availableTasks = [];
                    if (taskState is TaskLoaded) {
                      availableTasks = taskState.tasks;
                    }

                    if (availableTasks.isNotEmpty) {
                      selectedTask ??= availableTasks.first;

                      return DropdownButtonFormField<Task>(
                        initialValue: selectedTask,
                        decoration: InputDecoration(
                          labelText: 'Select Related Task / Project',
                          filled: true,
                          fillColor: AppColors.chipBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: availableTasks
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedTask = val;
                              projectController.text = val.title;
                            });
                          }
                        },
                      );
                    }

                    return TextField(
                      controller: projectController,
                      decoration: InputDecoration(
                        hintText: 'Project Name',
                        filled: true,
                        fillColor: AppColors.chipBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: priority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    filled: true,
                    fillColor: AppColors.chipBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: TaskPriority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => priority = val);
                  },
                ),
                const SizedBox(height: 12),

                // Date Picker Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.subText)),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMMM yyyy').format(goalDueDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: modalCtx,
                          initialDate: goalDueDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          setModalState(() => goalDueDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.darkText),
                      label: const Text('Change Date', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blackButton,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      final effectiveProjectName = selectedTask != null
                          ? selectedTask!.title
                          : (projectController.text.trim().isNotEmpty
                              ? projectController.text.trim()
                              : 'Charty App');

                      final newGoal = TaskGoal(
                        id: '',
                        taskId: selectedTask?.id ?? '00000000-0000-0000-0000-000000000001',
                        title: titleController.text.trim(),
                        projectName: effectiveProjectName,
                        priority: priority,
                        isCompleted: false,
                        dueDate: goalDueDate,
                        createdAt: DateTime.now(),
                      );

                      if (goalBloc != null) {
                        goalBloc.add(CreateGoalRequested(newGoal));
                      } else {
                        context.read<GoalBloc>().add(CreateGoalRequested(newGoal));
                      }

                      setState(() {
                        _selectedDate = goalDueDate;
                        _selectedMonth = DateTime(goalDueDate.year, goalDueDate.month, 1);
                      });
                      Navigator.pop(modalCtx);
                    },
                    child: const Text(
                      'Add Goal',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (taskBloc != null) {
          return BlocProvider<TaskBloc>.value(
            value: taskBloc,
            child: content,
          );
        }
        return content;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<GoalBloc, GoalState>(
          builder: (context, state) {
            List<TaskGoal> allGoals = [];
            if (state is GoalLoaded) {
              allGoals = state.goals;
            }

            final goalsForSelectedDate = allGoals.where((g) {
              final targetDate = g.dueDate ?? g.createdAt;
              return _isSameDay(targetDate, _selectedDate);
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Navigation & Today Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.darkText),
                            onPressed: _previousMonth,
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedMonth),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.darkText),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.chipBackground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _resetToToday,
                        icon: const Icon(Icons.today_rounded, size: 16, color: AppColors.darkText),
                        label: const Text(
                          'Today',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Calendar Grid Container (Displays Goals)
                  _buildCalendarGrid(allGoals),

                  const SizedBox(height: 24),

                  // Selected Date Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSameDay(_selectedDate, DateTime.now())
                                ? "Today's Scheduled Goals"
                                : "Goals for ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            "${goalsForSelectedDate.length} goal(s) scheduled",
                            style: const TextStyle(fontSize: 12, color: AppColors.subText),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _showCreateGoalModal(context),
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.darkText, size: 22),
                        tooltip: 'Add goal for this date',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Goals for Selected Date
                  if (goalsForSelectedDate.isNotEmpty)
                    ...goalsForSelectedDate.map((goal) => _buildGoalCard(context, goal))
                  else
                    _buildEmptyDateState(context),

                  const SizedBox(height: 24),

                  // All Active Goals / Tasks Section
                  if (allGoals.isNotEmpty) ...[
                    const Text(
                      "All Active Goals & Tasks",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...allGoals.take(5).map((goal) => _buildGoalCard(context, goal, isCompact: true)),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(List<TaskGoal> goals) {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final totalGridItems = startingWeekday + daysInMonth;

    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map((w) => SizedBox(
                      width: 32,
                      child: Text(
                        w,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalGridItems,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < startingWeekday) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - startingWeekday + 1;
              final cellDate = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
              final isSelected = _isSameDay(cellDate, _selectedDate);
              final isToday = _isSameDay(cellDate, DateTime.now());

              // Check if any goal has due date or created date on cellDate
              final hasGoalOnDay = goals.any((g) {
                final target = g.dueDate ?? g.createdAt;
                return _isSameDay(target, cellDate);
              });

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = cellDate),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blackButton
                        : (isToday
                            ? AppColors.primaryCard
                            : (hasGoalOnDay ? AppColors.accentYellow.withValues(alpha: 0.5) : Colors.transparent)),
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.darkText, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday || hasGoalOnDay ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.darkText,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: 4,
                        height: 4,
                        child: hasGoalOnDay
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppColors.darkText,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, TaskGoal goal, {bool isCompact = false}) {
    String displayProjectName = goal.projectName;
    try {
      final taskState = context.read<TaskBloc>().state;
      if (taskState is TaskLoaded) {
        final matching = taskState.tasks.where((t) => t.id == goal.taskId);
        if (matching.isNotEmpty && matching.first.title.isNotEmpty) {
          displayProjectName = matching.first.title;
        }
      }
    } catch (_) {}
    if (displayProjectName.isEmpty) {
      displayProjectName = 'Charty App';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _navigateToTaskDetail(context, goal),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: goal.isCompleted,
                activeColor: AppColors.blackButton,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (_) {
                  context.read<GoalBloc>().add(ToggleGoalRequested(goal));
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                        decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.chipBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            displayProjectName,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.subText),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (goal.dueDate != null) ...[
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.subText),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM').format(goal.dueDate!),
                            style: const TextStyle(fontSize: 11, color: AppColors.subText),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildPriorityPill(goal.priority),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.subText, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDateState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, size: 36, color: AppColors.subText),
          const SizedBox(height: 8),
          const Text(
            'No goals scheduled on this date',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select another date or add a new goal for this date.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.subText),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCard,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _showCreateGoalModal(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.darkText),
            label: const Text('Add Goal for this Date', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityPill(TaskPriority priority) {
    Color bg;
    Color fg;

    switch (priority) {
      case TaskPriority.low:
        bg = Colors.grey.shade200;
        fg = AppColors.darkText;
        break;
      case TaskPriority.medium:
        bg = AppColors.accentYellow;
        fg = AppColors.darkText;
        break;
      case TaskPriority.high:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
