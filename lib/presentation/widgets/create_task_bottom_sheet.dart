import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../theme/app_colors.dart';

class CreateTaskBottomSheet extends StatefulWidget {
  final String workspaceId;
  final Function(Task) onTaskCreated;

  const CreateTaskBottomSheet({
    super.key,
    required this.workspaceId,
    required this.onTaskCreated,
  });

  @override
  State<CreateTaskBottomSheet> createState() => _CreateTaskBottomSheetState();
}

class _CreateTaskBottomSheetState extends State<CreateTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            'Create New Task',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Task Title',
              filled: true,
              fillColor: AppColors.chipBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Description (optional)',
              filled: true,
              fillColor: AppColors.chipBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
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
                    if (val != null) setState(() => _priority = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TaskStatus>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    filled: true,
                    fillColor: AppColors.chipBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: TaskStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
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
                if (_titleController.text.trim().isEmpty) return;
                final newTask = Task(
                  id: '',
                  workspaceId: widget.workspaceId,
                  title: _titleController.text.trim(),
                  description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                  status: _status,
                  priority: _priority,
                  position: 0,
                  progress: 0.1,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                widget.onTaskCreated(newTask);
                Navigator.pop(context);
              },
              child: const Text(
                'Create Task',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
