import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../theme/app_colors.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  int _selectedSubTab = 0; // 0: Goals, 1: Chat

  final List<Map<String, dynamic>> _subTasks = [
    {'title': 'Design system', 'project': 'Charty App', 'priority': TaskPriority.high, 'completed': true},
    {'title': 'Landing Page', 'project': 'Charty App', 'priority': TaskPriority.high, 'completed': false},
    {'title': 'Pricing Page', 'project': 'Charty App', 'priority': TaskPriority.low, 'completed': false},
    {'title': 'Copywriting', 'project': 'Charty App', 'priority': TaskPriority.high, 'completed': false},
  ];

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
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.darkText),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.darkText),
                        onPressed: () {},
                      ),
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
                  const SizedBox(height: 8),
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
                                  : "6 August",
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('People', style: TextStyle(fontSize: 12, color: AppColors.subText)),
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
                              child: _buildAvatar('https://i.pravatar.cc/100?img=15'),
                            ),
                          ],
                        ),
                      ],
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

            // Sub-tasks List or Chat View
            if (_selectedSubTab == 0) ...[
              ..._subTasks.map((item) => _buildSubTaskTile(item)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('No messages yet in project discussion.', style: TextStyle(color: AppColors.subText)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubTaskTile(Map<String, dynamic> item) {
    final isCompleted = item['completed'] as bool;
    final priority = item['priority'] as TaskPriority;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppColors.priorityLow : AppColors.subText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  item['project'],
                  style: const TextStyle(fontSize: 12, color: AppColors.subText),
                ),
              ],
            ),
          ),
          _buildPriorityPill(priority),
          const SizedBox(width: 4),
          const Icon(Icons.more_vert, size: 18, color: AppColors.subText),
        ],
      ),
    );
  }

  Widget _buildPriorityPill(TaskPriority priority) {
    String label = 'High';
    Color color = AppColors.priorityHigh;
    if (priority == TaskPriority.low) {
      label = 'Low';
      color = AppColors.priorityLow;
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
