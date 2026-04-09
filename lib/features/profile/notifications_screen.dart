import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _dailyCheckIn = true;
  bool _moodReminder = true;
  bool _journalReminder = false;
  bool _weeklyReport = true;
  bool _communityUpdates = false;
  bool _breathingReminder = true;

  TimeOfDay _checkInTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _journalTime = const TimeOfDay(hour: 21, minute: 0);

  Future<void> _pickTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime : _journalTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _journalTime = picked;
        }
      });
      _showSavedSnack();
    }
  }

  void _showSavedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification preferences saved!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Notifications',
            style: AppTypography.heading3.copyWith(color: AppColors.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications help you stay consistent with your wellness journey.',
                      style: AppTypography.body2
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _buildSectionHeader('Daily Reminders'),
            const SizedBox(height: 12),
            _buildNotificationCard(
              icon: Icons.wb_sunny_outlined,
              iconColor: const Color(0xFFED8936),
              iconBg: const Color(0xFFFFF3E8),
              title: 'Daily Check-in',
              subtitle: 'Remind me to log how I\'m feeling',
              value: _dailyCheckIn,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _dailyCheckIn = v);
                _showSavedSnack();
              },
              trailing: _dailyCheckIn
                  ? _buildTimeTile(_formatTime(_checkInTime),
                      () => _pickTime(true))
                  : null,
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              icon: Icons.favorite_outline_rounded,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFEDE9FF),
              title: 'Mood Reminder',
              subtitle: 'Prompt me to track my mood',
              value: _moodReminder,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _moodReminder = v);
                _showSavedSnack();
              },
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              icon: Icons.book_outlined,
              iconColor: const Color(0xFF805AD5),
              iconBg: const Color(0xFFF3EEFF),
              title: 'Journal Reminder',
              subtitle: 'Remind me to write in my journal',
              value: _journalReminder,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _journalReminder = v);
                _showSavedSnack();
              },
              trailing: _journalReminder
                  ? _buildTimeTile(_formatTime(_journalTime),
                      () => _pickTime(false))
                  : null,
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              icon: Icons.air_rounded,
              iconColor: const Color(0xFF3182CE),
              iconBg: const Color(0xFFEBF4FF),
              title: 'Breathing Reminder',
              subtitle: 'Take a breathing break during the day',
              value: _breathingReminder,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _breathingReminder = v);
                _showSavedSnack();
              },
            ),

            const SizedBox(height: 28),

            _buildSectionHeader('Reports & Updates'),
            const SizedBox(height: 12),
            _buildNotificationCard(
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF38A169),
              iconBg: const Color(0xFFEAF7EF),
              title: 'Weekly Wellness Report',
              subtitle: 'Get a summary of your week every Sunday',
              value: _weeklyReport,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _weeklyReport = v);
                _showSavedSnack();
              },
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              icon: Icons.people_outline_rounded,
              iconColor: AppColors.secondary,
              iconBg: const Color(0xFFEEF8FF),
              title: 'Community Updates',
              subtitle: 'Hear about new posts and replies',
              value: _communityUpdates,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _communityUpdates = v);
                _showSavedSnack();
              },
            ),

            const SizedBox(height: 32),

            // Save all button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showSavedSnack();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Save Preferences', style: AppTypography.button),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style:
          AppTypography.heading4.copyWith(color: AppColors.onSurface),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTypography.body1
                              .copyWith(color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppTypography.body2
                              .copyWith(color: AppColors.onSurfaceMuted)),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const Divider(height: 1, color: Color(0xFFEDE9FF)),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildTimeTile(String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded,
                color: AppColors.onSurfaceMuted, size: 18),
            const SizedBox(width: 10),
            Text('Reminder time',
                style: AppTypography.body2
                    .copyWith(color: AppColors.onSurfaceMuted)),
            const Spacer(),
            Text(time,
                style: AppTypography.body2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceMuted, size: 18),
          ],
        ),
      ),
    );
  }
}