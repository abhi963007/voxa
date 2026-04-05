import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/task_provider.dart';
import '../../core/models/task_model.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final now = DateTime.now();
    final reminders = taskProvider.reminders;

    final todayReminders = reminders.where((r) {
      final d = r.scheduledTime;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();

    final tomorrowReminders = reminders.where((r) {
      final d = r.scheduledTime;
      final tomorrow = now.add(const Duration(days: 1));
      return d.year == tomorrow.year &&
          d.month == tomorrow.month &&
          d.day == tomorrow.day;
    }).toList();

    final pendingTasks =
        taskProvider.todayTasks.where((t) => !t.isCompleted).toList();

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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminders',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '${todayReminders.length} upcoming today',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Today section
                  if (todayReminders.isNotEmpty) ...[
                    _TimelineHeader(
                        label:
                            'Today · ${DateFormat('MMMM d').format(now)}'),
                    const SizedBox(height: 16),
                    ...todayReminders.asMap().entries.map(
                          (e) => _ReminderTimelineCard(
                            reminder: e.value,
                            isUpcoming:
                                e.value.scheduledTime.isAfter(now),
                            onToggle: () => taskProvider
                                .toggleReminder(e.value.id),
                          )
                              .animate(
                                  delay: Duration(milliseconds: e.key * 80))
                              .fadeIn()
                              .slideX(begin: 0.1),
                        ),
                    const SizedBox(height: 24),
                  ],

                  // Tomorrow section
                  if (tomorrowReminders.isNotEmpty) ...[
                    _TimelineHeader(
                        label:
                            'Tomorrow · ${DateFormat('MMMM d').format(now.add(const Duration(days: 1)))}'),
                    const SizedBox(height: 16),
                    ...tomorrowReminders.asMap().entries.map(
                          (e) => _ReminderTimelineCard(
                            reminder: e.value,
                            isUpcoming: true,
                            onToggle: () => taskProvider
                                .toggleReminder(e.value.id),
                          )
                              .animate()
                              .fadeIn(),
                        ),
                    const SizedBox(height: 24),
                  ],

                  // AI nudge
                  if (pendingTasks.isNotEmpty)
                    _AiNudgeCard(
                      pendingCount: pendingTasks.length,
                      onAccept: () async {
                        for (final task in pendingTasks) {
                          await taskProvider.addReminder(
                            title: task.title,
                            scheduledTime:
                                task.dueTime ??
                                    DateTime.now()
                                        .add(const Duration(hours: 1)),
                            addedViaVoice: false,
                          );
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reminders set for ${pendingTasks.length} tasks!',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    ).animate().fadeIn(delay: 400.ms),

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

class _TimelineHeader extends StatelessWidget {
  final String label;
  const _TimelineHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ReminderTimelineCard extends StatelessWidget {
  final ReminderModel reminder;
  final bool isUpcoming;
  final VoidCallback onToggle;

  const _ReminderTimelineCard({
    required this.reminder,
    required this.isUpcoming,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(reminder.scheduledTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time label
          SizedBox(
            width: 64,
            child: Text(
              timeStr,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUpcoming
                    ? AppColors.primaryLight
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),

          // Timeline line
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: AppColors.outlineVariant,
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUpcoming
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                ),
              ),
              Container(
                width: 2,
                height: 10,
                color: AppColors.outlineVariant,
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Card
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: isUpcoming
                    ? Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3))
                    : null,
                boxShadow: isUpcoming
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 12,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUpcoming
                          ? const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.accent
                              ],
                            )
                          : null,
                      color: isUpcoming
                          ? null
                          : AppColors.surfaceBright,
                    ),
                    child: Icon(
                      isUpcoming
                          ? Icons.notifications_rounded
                          : Icons.notifications_off_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (reminder.addedViaVoice || reminder.isRecurring)
                          const SizedBox(height: 3),
                        Row(
                          children: [
                            if (reminder.addedViaVoice) ...[
                              Icon(Icons.mic_rounded,
                                  size: 10,
                                  color: AppColors.accentLight),
                              const SizedBox(width: 3),
                              Text(
                                'Added via voice',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.accentLight,
                                ),
                              ),
                            ],
                            if (reminder.isRecurring) ...[
                              if (reminder.addedViaVoice)
                                const SizedBox(width: 8),
                              Icon(Icons.loop_rounded,
                                  size: 10,
                                  color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(
                                'Recurring daily',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: reminder.isActive,
                    onChanged: (_) => onToggle(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiNudgeCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onAccept;

  const _AiNudgeCard({required this.pendingCount, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.accentLight, size: 16),
              const SizedBox(width: 6),
              Text(
                'AI Insight',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentLight,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You have $pendingCount task${pendingCount != 1 ? 's' : ''} without reminders today. Want me to set them for you?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: onAccept,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDim],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Yes, set them',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'No thanks',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

