import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/task_provider.dart';
import '../../core/models/task_model.dart';
import '../../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _filter = 0; // 0=All, 1=Today, 2=Week, 3=Completed

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    List<TaskModel> displayTasks;
    final now = DateTime.now();
    switch (_filter) {
      case 1:
        displayTasks = taskProvider.todayTasks;
        break;
      case 2:
        displayTasks = taskProvider.tasks.where((t) {
          if (t.dueTime == null) return false;
          final diff = t.dueTime!.difference(now).inDays;
          return diff >= 0 && diff <= 7;
        }).toList();
        break;
      case 3:
        displayTasks = taskProvider.completedTasks;
        break;
      default:
        displayTasks = taskProvider.tasks;
    }

    final highPriority =
        displayTasks.where((t) => t.priority >= 1 && !t.isCompleted).toList();
    final normalTasks =
        displayTasks.where((t) => t.priority == 0 && !t.isCompleted).toList();
    final completed =
        displayTasks.where((t) => t.isCompleted).toList();

    final total = taskProvider.tasks.length;
    final done = taskProvider.completedTasks.length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'My Tasks',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded,
                            color: AppColors.onSurfaceVariant),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filter tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                            label: 'All',
                            active: _filter == 0,
                            onTap: () => setState(() => _filter = 0)),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: 'Today',
                            active: _filter == 1,
                            onTap: () => setState(() => _filter = 1)),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: 'This Week',
                            active: _filter == 2,
                            onTap: () => setState(() => _filter = 2)),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: 'Completed',
                            active: _filter == 3,
                            onTap: () => setState(() => _filter = 3)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Progress card
                  _ProgressCard(done: done, total: total),

                  const SizedBox(height: 24),

                  // Task sections
                  if (highPriority.isNotEmpty) ...[
                    _SectionHeader(
                        label: 'HIGH PRIORITY', color: AppColors.warning),
                    const SizedBox(height: 10),
                    ...highPriority.asMap().entries.map(
                          (e) => TaskCard(task: e.value)
                              .animate(
                                  delay: Duration(milliseconds: e.key * 60))
                              .fadeIn()
                              .slideX(begin: 0.1),
                        ),
                    const SizedBox(height: 20),
                  ],

                  if (normalTasks.isNotEmpty) ...[
                    _SectionHeader(
                        label: 'NORMAL PRIORITY',
                        color: AppColors.onSurfaceVariant),
                    const SizedBox(height: 10),
                    ...normalTasks.asMap().entries.map(
                          (e) => TaskCard(task: e.value)
                              .animate(
                                  delay: Duration(milliseconds: e.key * 60))
                              .fadeIn()
                              .slideX(begin: 0.1),
                        ),
                    const SizedBox(height: 20),
                  ],

                  if (completed.isNotEmpty) ...[
                    _SectionHeader(
                        label: 'COMPLETED', color: AppColors.success),
                    const SizedBox(height: 10),
                    ...completed.asMap().entries.map(
                          (e) => TaskCard(task: e.value)
                              .animate(
                                  delay: Duration(milliseconds: e.key * 60))
                              .fadeIn(),
                        ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDim])
              : null,
          color: active ? null : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? null
              : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressCard({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceContainerHigh,
            AppColors.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$done of $total tasks done today',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceBright,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total - done > 0
                ? '${total - done} task${total - done != 1 ? 's' : ''} remaining · Keep going!'
                : 'All done! 🎉 Amazing work!',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

