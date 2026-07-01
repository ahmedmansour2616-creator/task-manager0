import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
  });

  Color _borderColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.late:
        return AppColors.late;
      case TaskStatus.pending:
        return AppColors.pending;
      case TaskStatus.done:
        return AppColors.ok;
    }
  }

  Color _badgeBg(TaskStatus s) {
    switch (s) {
      case TaskStatus.late:
        return AppColors.lateBg;
      case TaskStatus.pending:
        return AppColors.pendingBg;
      case TaskStatus.done:
        return AppColors.okBg;
    }
  }

  Color _badgeFg(TaskStatus s) {
    switch (s) {
      case TaskStatus.late:
        return AppColors.late;
      case TaskStatus.pending:
        return AppColors.pending;
      case TaskStatus.done:
        return AppColors.ok;
    }
  }

  String _badgeText(TaskStatus s) {
    switch (s) {
      case TaskStatus.late:
        return 'متأخرة';
      case TaskStatus.pending:
        return 'قيد التنفيذ';
      case TaskStatus.done:
        return 'مكتملة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x14222F3F), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 74,
            decoration: BoxDecoration(
              color: _borderColor(status),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 12, left: 4),
            child: GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? AppColors.ok : Colors.white,
                  border: Border.all(
                    color: task.completed ? AppColors.ok : AppColors.line,
                    width: 2,
                  ),
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      decoration:
                          status == TaskStatus.done ? TextDecoration.lineThrough : null,
                      color: status == TaskStatus.done
                          ? AppColors.inkSoft
                          : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _badgeBg(status),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _badgeText(status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _badgeFg(status),
                          ),
                        ),
                      ),
                      if (task.time.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('🕒 ${task.time}',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.inkSoft)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.inkSoft),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
