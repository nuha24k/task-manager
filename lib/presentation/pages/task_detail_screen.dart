import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_goal.dart';
import '../../injection.dart';
import '../blocs/task_bloc.dart';
import '../blocs/goal_bloc.dart';
import '../blocs/chat_bloc.dart';
import '../blocs/auth_bloc.dart';
import '../theme/app_colors.dart';
import '../widgets/task_share_modal.dart';


class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final int initialTab;

  const TaskDetailScreen({
    super.key,
    required this.task,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GoalBloc>(
          create: (_) => sl<GoalBloc>()..add(WatchGoalsRequested(task.id)),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => sl<ChatBloc>()..add(WatchCommentsRequested(task.id)),
        ),
      ],
      child: _TaskDetailView(task: task, initialTab: initialTab),
    );
  }
}

class _TaskDetailView extends StatefulWidget {
  final Task task;
  final int initialTab;

  const _TaskDetailView({required this.task, this.initialTab = 0});

  @override
  State<_TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<_TaskDetailView> {
  late int _selectedSubTab;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialTab;
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _confirmDeleteTask(BuildContext context) {
    TaskBloc taskBloc;
    try {
      taskBloc = context.read<TaskBloc>();
    } catch (_) {
      taskBloc = sl<TaskBloc>();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Task', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.subText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              taskBloc.add(DeleteTaskRequested(widget.task.id));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddGoalBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final projectController = TextEditingController(text: widget.task.title);
    TaskPriority priority = TaskPriority.medium;
    DateTime? dueDate = DateTime.now().add(const Duration(days: 3));

    final goalBloc = context.read<GoalBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctxStateful, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add New Goal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Goal title (e.g. Design system)',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: projectController,
                    decoration: InputDecoration(
                      hintText: 'Project Name (e.g. Charty App)',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority Selector
                  const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subText)),
                  const SizedBox(height: 8),
                  Row(
                    children: TaskPriority.values.map((p) {
                      final isSelected = p == priority;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p.name.toUpperCase(), style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.darkText,
                          )),
                          selected: isSelected,
                          selectedColor: AppColors.darkText,
                          backgroundColor: AppColors.background,
                          onSelected: (val) {
                            if (val) setModalState(() => priority = p);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Due Date Picker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subText)),
                          const SizedBox(height: 4),
                          Text(
                            dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate!) : 'No due date',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setModalState(() => dueDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.darkText),
                        label: const Text('Change Date', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;

                        final newGoal = TaskGoal(
                          id: '',
                          taskId: widget.task.id,
                          title: titleController.text.trim(),
                          projectName: projectController.text.trim().isEmpty
                              ? 'Charty App'
                              : projectController.text.trim(),
                          priority: priority,
                          isCompleted: false,
                          dueDate: dueDate,
                          createdAt: DateTime.now(),
                        );

                        goalBloc.add(CreateGoalRequested(newGoal));
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditGoalBottomSheet(BuildContext context, TaskGoal goal) {
    final titleController = TextEditingController(text: goal.title);
    final projectController = TextEditingController(text: goal.projectName);
    TaskPriority priority = goal.priority;
    DateTime? dueDate = goal.dueDate;

    final goalBloc = context.read<GoalBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctxStateful, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Goal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Goal title',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: projectController,
                    decoration: InputDecoration(
                      hintText: 'Project Name',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority Selector
                  const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subText)),
                  const SizedBox(height: 8),
                  Row(
                    children: TaskPriority.values.map((p) {
                      final isSelected = p == priority;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p.name.toUpperCase(), style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.darkText,
                          )),
                          selected: isSelected,
                          selectedColor: AppColors.darkText,
                          backgroundColor: AppColors.background,
                          onSelected: (val) {
                            if (val) setModalState(() => priority = p);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Due Date Picker Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.subText)),
                          const SizedBox(height: 4),
                          Text(
                            dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate!) : 'No due date',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setModalState(() => dueDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.darkText),
                        label: const Text('Change Date', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;

                        final updatedGoal = goal.copyWith(
                          title: titleController.text.trim(),
                          projectName: projectController.text.trim(),
                          priority: priority,
                          dueDate: dueDate,
                        );

                        goalBloc.add(UpdateGoalRequested(updatedGoal));
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sendChatMessage(BuildContext context) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    String userId = 'user_anonymous';
    if (authState is Authenticated) {
      userId = authState.user.id;
    }

    context.read<ChatBloc>().add(SendCommentRequested(
      taskId: widget.task.id,
      content: text,
      userId: userId,
    ));

    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.darkText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: AppColors.darkText),
              tooltip: 'Share & Add People',
              onPressed: () => TaskShareModal.show(context, widget.task),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
              tooltip: 'Delete Task',
              onPressed: () => _confirmDeleteTask(context),
            ),
          ),
        ],

      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hero Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCard,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.space_dashboard_rounded, size: 18, color: AppColors.darkText),
                            ),
                            _buildStatusPill(widget.task.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.task.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.task.description!,
                            style: const TextStyle(fontSize: 14, color: AppColors.subText),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Text('Created by ', style: TextStyle(fontSize: 13, color: AppColors.subText)),
                            CircleAvatar(
                              radius: 10,
                              backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12'),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Agnes Nielsen',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deadline & People Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Deadline', style: TextStyle(fontSize: 12, color: AppColors.subText)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryCard,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.darkText),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.task.dueDate != null
                                        ? "${widget.task.dueDate!.day} ${_monthName(widget.task.dueDate!.month)}"
                                        : "No deadline",
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => TaskShareModal.show(context, widget.task),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('People', style: TextStyle(fontSize: 12, color: AppColors.subText)),
                                    Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.subText),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildAvatar('https://i.pravatar.cc/100?img=5'),
                                    Transform.translate(
                                      offset: const Offset(-8, 0),
                                      child: _buildAvatar('https://i.pravatar.cc/100?img=8'),
                                    ),
                                    Transform.translate(
                                      offset: const Offset(-16, 0),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primaryCard,
                                        child: const Icon(Icons.add, size: 14, color: AppColors.darkText),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tab Switcher (Goals / Chat)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSubTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedSubTab == 0 ? AppColors.chipBackground : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Goals',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedSubTab == 0 ? AppColors.darkText : AppColors.subText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSubTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedSubTab == 1 ? AppColors.chipBackground : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Chat',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedSubTab == 1 ? AppColors.darkText : AppColors.subText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SubTab 0: GOALS VIEW
                  if (_selectedSubTab == 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Task Goals',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddGoalBottomSheet(context),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.darkText),
                          label: const Text(
                            'Add Goal',
                            style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<GoalBloc, GoalState>(
                      builder: (context, state) {
                        if (state is GoalLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (state is GoalError) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Error loading goals: ${state.message}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        if (state is GoalLoaded) {
                          if (state.goals.isEmpty) {
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
                                  const Text('No goals added yet.', style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryCard,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => _showAddGoalBottomSheet(context),
                                    child: const Text('Create First Goal', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: state.goals.map((goal) => _buildGoalTile(context, goal)).toList(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ] else ...[
                    // SubTab 1: CHAT VIEW
                    BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state is ChatLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (state is ChatError) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('Error loading chat: ${state.message}', style: const TextStyle(color: Colors.red)),
                          );
                        }
                        if (state is ChatLoaded) {
                          if (state.comments.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppColors.subText),
                                  SizedBox(height: 8),
                                  Text(
                                    'No messages yet in project discussion.\nStart the conversation below!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.subText),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.comments.length,
                            itemBuilder: (ctx, index) {
                              final comment = state.comments[index];
                              return _buildChatMessageTile(context, comment);
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Bar for Chat Tab input field
          if (_selectedSubTab == 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendChatMessage(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppColors.darkText,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        onPressed: () => _sendChatMessage(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalTile(BuildContext context, TaskGoal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              context.read<GoalBloc>().add(ToggleGoalRequested(goal));
            },
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              goal.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: goal.isCompleted ? AppColors.priorityLow : AppColors.subText,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      goal.projectName,
                      style: const TextStyle(fontSize: 12, color: AppColors.subText),
                    ),
                    if (goal.dueDate != null) ...[
                      const Text(' • ', style: TextStyle(fontSize: 12, color: AppColors.subText)),
                      Icon(Icons.event, size: 12, color: AppColors.subText),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('dd MMM').format(goal.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: goal.dueDate!.isBefore(DateTime.now()) && !goal.isCompleted
                              ? Colors.red.shade700
                              : AppColors.subText,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildPriorityPill(goal.priority),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.subText),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditGoalBottomSheet(context, goal);
              } else if (value == 'delete') {
                context.read<GoalBloc>().add(DeleteGoalRequested(goal.id));
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.darkText),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessageTile(BuildContext context, TaskComment comment) {
    final formattedTime = DateFormat('HH:mm').format(comment.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryCard,
            child: Text(
              comment.userId.isNotEmpty ? comment.userId.substring(0, 1).toUpperCase() : 'U',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User ${comment.userId.length > 6 ? comment.userId.substring(0, 6) : comment.userId}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkText),
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 11, color: AppColors.subText),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14, color: AppColors.darkText, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(TaskStatus status) {
    String label = 'To Do';
    if (status == TaskStatus.inProgress) label = 'In Progress';
    if (status == TaskStatus.done) label = 'Done';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkText),
      ),
    );
  }

  Widget _buildPriorityPill(TaskPriority priority) {
    String label = 'High';
    Color color = AppColors.priorityHigh;
    if (priority == TaskPriority.low) {
      label = 'Low';
      color = AppColors.priorityLow;
    } else if (priority == TaskPriority.medium) {
      label = 'Med';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return CircleAvatar(
      radius: 13,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(url),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
