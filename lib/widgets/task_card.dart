import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/task_provider.dart';
import '../core/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 22),
        ),
        onDismissed: (_) => taskProvider.deleteTask(task.id),
        child: Container(
          decoration: BoxDecoration(
            color: task.isCompleted
                ? AppColors.surfaceContainerHigh.withValues(alpha: 0.4)
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: _priorityColor(task.priority),
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => taskProvider.toggleTask(task.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: task.isCompleted
                          ? const LinearGradient(
                              colors: [AppColors.success, Color(0xFF059669)])
                          : null,
                      border: task.isCompleted
                          ? null
                          : Border.all(
                              color: AppColors.primary, width: 1.5),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 13)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: task.isCompleted
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Voice badge
                          if (task.addedViaVoice) ...[
                            Icon(Icons.mic_rounded,
                                size: 11,
                                color: AppColors.accentLight),
                            const SizedBox(width: 3),
                          ],
                          // Time
                          if (task.dueTime != null) ...[
                            Icon(Icons.schedule_rounded,
                                size: 11,
                                color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(
                              task.isCompleted
                                  ? 'Done ${DateFormat('h:mm a').format(task.dueTime!)}'
                                  : DateFormat('h:mm a')
                                      .format(task.dueTime!),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: task.isCompleted
                                    ? AppColors.success
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                          // Category
                          if (task.category != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.category!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Priority chip + time chip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (task.priority > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _priorityColor(task.priority)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority == 2 ? 'Urgent' : 'High',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _priorityColor(task.priority),
                          ),
                        ),
                      ),
                    if (task.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 2:
        return AppColors.error;
      case 1:
        return AppColors.warning;
      default:
        return AppColors.primary.withValues(alpha: 0.5);
    }
  }
}

