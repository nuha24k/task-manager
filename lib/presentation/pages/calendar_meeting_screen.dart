import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../blocs/task_bloc.dart';
import '../theme/app_colors.dart';
import '../widgets/create_task_bottom_sheet.dart';
import 'task_detail_screen.dart';

class CalendarMeetingScreen extends StatefulWidget {
  const CalendarMeetingScreen({super.key});

  @override
  State<CalendarMeetingScreen> createState() => _CalendarMeetingScreenState();
}

class _CalendarMeetingScreenState extends State<CalendarMeetingScreen> {
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
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _navigateToDetail(BuildContext context, Task task, {int initialTab = 0}) {
    TaskBloc taskBloc;
    try {
      taskBloc = context.read<TaskBloc>();
    } catch (_) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: taskBloc,
          child: TaskDetailScreen(task: task, initialTab: initialTab),
        ),
      ),
    );
  }

  void _showCreateTaskModal(BuildContext context) {
    TaskBloc taskBloc;
    try {
      taskBloc = context.read<TaskBloc>();
    } catch (_) {
      return;
    }

    // ponytail: static fallback workspace -> use active workspace ID from parent context
    const workspaceId = '00000000-0000-0000-0000-000000000001';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: taskBloc,
        child: CreateTaskBottomSheet(
          workspaceId: workspaceId,
          onTaskCreated: (newTask) {
            final taskWithDate = newTask.copyWith(dueDate: _selectedDate);
            taskBloc.add(CreateTaskRequested(taskWithDate));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            List<Task> allTasks = [];
            if (state is TaskLoaded) {
              allTasks = state.tasks;
            }

            final tasksForSelectedDate = allTasks.where((t) => _isSameDay(t.dueDate, _selectedDate)).toList();

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

                  // Calendar Grid Container
                  _buildCalendarGrid(allTasks),

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
                                ? "Today's Projects & Schedule"
                                : "Schedule for ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          Text(
                            "${tasksForSelectedDate.length} project(s) scheduled",
                            style: const TextStyle(fontSize: 12, color: AppColors.subText),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _showCreateTaskModal(context),
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.darkText, size: 22),
                        tooltip: 'Add task for this date',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tasks / Projects for Selected Date
                  if (tasksForSelectedDate.isNotEmpty)
                    ...tasksForSelectedDate.map((task) => _buildProjectCard(context, task))
                  else
                    _buildEmptyDateState(context),

                  const SizedBox(height: 24),

                  // Active Projects Section
                  if (allTasks.isNotEmpty) ...[
                    const Text(
                      "All Active Projects",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...allTasks.take(3).map((task) => _buildProjectCard(context, task, isCompact: true)),
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

  Widget _buildCalendarGrid(List<Task> tasks) {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sun, 1 = Mon ...
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

              // Check if any project has due date on cellDate
              final hasTaskOnDay = tasks.any((t) => _isSameDay(t.dueDate, cellDate));

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = cellDate),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blackButton
                        : (isToday
                            ? AppColors.primaryCard
                            : (hasTaskOnDay ? AppColors.accentYellow.withValues(alpha: 0.5) : Colors.transparent)),
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.darkText, width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday || hasTaskOnDay ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.darkText,
                        ),
                      ),
                      if (hasTaskOnDay && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.darkText,
                              shape: BoxShape.circle,
                            ),
                          ),
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

  Widget _buildProjectCard(BuildContext context, Task task, {bool isCompact = false}) {
    final progressPercent = (task.progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusPill(task.status),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description!,
              style: const TextStyle(fontSize: 13, color: AppColors.subText),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.subText),
                  const SizedBox(width: 6),
                  Text(
                    task.dueDate != null ? DateFormat('dd MMM yyyy').format(task.dueDate!) : 'No due date',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkText),
                  ),
                ],
              ),
              Text('$progressPercent%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.subText)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: task.progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.chipBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                task.status == TaskStatus.done
                    ? Colors.green
                    : (task.priority == TaskPriority.high ? AppColors.priorityHigh : AppColors.darkText),
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Action Buttons: Goals & Chat
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppColors.chipBackground),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _navigateToDetail(context, task, initialTab: 0),
                  icon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.darkText),
                  label: const Text('Project Goals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blackButton,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _navigateToDetail(context, task, initialTab: 1),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                  label: const Text('Project Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
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
          const Icon(Icons.event_available_rounded, size: 36, color: AppColors.subText),
          const SizedBox(height: 8),
          const Text(
            'No projects due on this date',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select another date or add a project task for this date.',
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
            onPressed: () => _showCreateTaskModal(context),
            icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.darkText),
            label: const Text('Add Task for this Date', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(TaskStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case TaskStatus.todo:
        bg = Colors.grey.shade200;
        fg = AppColors.darkText;
        label = 'TO DO';
        break;
      case TaskStatus.inProgress:
        bg = AppColors.accentYellow;
        fg = AppColors.darkText;
        label = 'IN PROGRESS';
        break;
      case TaskStatus.done:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        label = 'DONE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
