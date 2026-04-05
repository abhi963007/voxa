import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _soundHaptics = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                children: [
                  // Profile section
                  _ProfileSection()
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.1),

                  const SizedBox(height: 28),

                  // Settings groups
                  _SettingsGroup(
                    title: 'VOICE & AI',
                    items: [
                      _SettingsItem(
                        icon: Icons.mic_rounded,
                        label: 'Voice Language',
                        trailing: 'English (US)',
                      ),
                      _SettingsItem(
                        icon: Icons.graphic_eq_rounded,
                        label: 'Voice Sensitivity',
                        trailing: 'High',
                      ),
                      _SettingsItem(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI Model',
                        trailingWidget: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.primary],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Gemini',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  _SettingsGroup(
                    title: 'NOTIFICATIONS',
                    items: [
                      _SettingsItem(
                        icon: Icons.notifications_rounded,
                        label: 'Push Notifications',
                        trailingWidget: Switch(
                          value: _pushNotifications,
                          onChanged: (v) =>
                              setState(() => _pushNotifications = v),
                        ),
                      ),
                      _SettingsItem(
                        icon: Icons.bedtime_rounded,
                        label: 'Do Not Disturb',
                        trailing: '10 PM – 7 AM',
                      ),
                      _SettingsItem(
                        icon: Icons.volume_up_rounded,
                        label: 'Sound & Haptics',
                        trailingWidget: Switch(
                          value: _soundHaptics,
                          onChanged: (v) =>
                              setState(() => _soundHaptics = v),
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  _SettingsGroup(
                    title: 'APP',
                    items: [
                      _SettingsItem(
                        icon: Icons.storage_rounded,
                        label: 'Data & Storage',
                      ),
                      _SettingsItem(
                        icon: Icons.shield_rounded,
                        label: 'Privacy',
                      ),
                      _SettingsItem(
                        icon: Icons.palette_rounded,
                        label: 'Appearance',
                        trailing: 'Dark Mode',
                      ),
                    ],
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  // Danger zone
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                      title: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {},
                    ),
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 20),

                  Text(
                    'Voxa v1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.outlineVariant,
                    ),
                  ),

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

class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'AK',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'Abhishek Kumar',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),

        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.primaryLight, size: 14),
            const SizedBox(width: 4),
            Text(
              'Premium member',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Stats row
        Row(
          children: [
            Expanded(
              child: _StatCard(value: '48', label: 'Tasks Done'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(value: '7d', label: 'Streak 🔥'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(value: '5', label: 'Reminders'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.accentGradient.createShader(bounds),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      indent: 52,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Widget? trailingWidget;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primaryLight),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailingWidget ??
          (trailing != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailing!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.outlineVariant, size: 18),
                  ],
                )
              : const Icon(Icons.chevron_right_rounded,
                  color: AppColors.outlineVariant, size: 18)),
      onTap: () {},
    );
  }
}

