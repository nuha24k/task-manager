import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../theme/app_colors.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final Color backgroundColor;
  final int? commentCount;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onEditTap,
    this.backgroundColor = AppColors.primaryCard,
    this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.space_dashboard_rounded,
                          size: 16,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEditTap != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.darkText),
                    onPressed: onEditTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusPill(task.status),
                const SizedBox(width: 8),
                _buildPriorityPill(task.priority),
              ],
            ),
            const SizedBox(height: 14),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: task.progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stacked Avatars based on assigneeIds
                _buildAssigneesList(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.subText),
                          const SizedBox(width: 4),
                          Text(
                            task.dueDate != null
                                ? "${task.dueDate!.day} ${_monthName(task.dueDate!.month)}"
                                : "No date",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.subText),
                          const SizedBox(width: 4),
                          Text(
                            commentCount != null ? (commentCount! < 10 ? '0$commentCount' : '$commentCount') : '00',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneesList() {
    final assignees = task.assigneeIds.isNotEmpty ? task.assigneeIds : ['u1', 'u2'];
    final displayAssignees = assignees.take(2).toList();
    final remaining = assignees.length - 2;

    return Row(
      children: [
        for (int i = 0; i < displayAssignees.length; i++)
          Transform.translate(
            offset: Offset(i * -8.0, 0),
            child: _buildAvatar('https://i.pravatar.cc/100?img=${(displayAssignees[i].hashCode % 70) + 1}'),
          ),
        if (remaining > 0)
          Transform.translate(
            offset: Offset(displayAssignees.length * -8.0, 0),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: Text(
                '+$remaining',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
      ],
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

  Widget _buildStatusPill(TaskStatus status) {
    String label = 'Ongoing';
    if (status == TaskStatus.todo) label = 'To Do';
    if (status == TaskStatus.done) label = 'Completed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 3, backgroundColor: AppColors.darkText),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.darkText),
          ),
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
    } else if (priority == TaskPriority.medium) {
      label = 'Medium';
      color = AppColors.priorityMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
