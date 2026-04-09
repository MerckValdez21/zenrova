import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _profileVisible = true;
  bool _shareJournalInsights = false;
  bool _shareMoodTrends = true;
  bool _analyticsEnabled = true;
  bool _biometricLock = false;
  bool _twoFactorEnabled = false;

  void _showSavedSnack([String msg = 'Privacy settings saved!']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style: AppTypography.heading4
                .copyWith(color: AppColors.onSurface)),
        content: Text(
          'This action is permanent and cannot be undone. All your journals, moods, and data will be erased.',
          style:
              AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style:
                    AppTypography.button.copyWith(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Account deletion request sent. You will be contacted within 48 hours.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0D9FF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Change Password',
                  style: AppTypography.heading3
                      .copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 20),
              _buildPasswordField('Current Password', currentCtrl),
              const SizedBox(height: 14),
              _buildPasswordField('New Password', newCtrl),
              const SizedBox(height: 14),
              _buildPasswordField('Confirm New Password', confirmCtrl),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppColors.primaryGradient,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSavedSnack('Password changed successfully!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Update Password',
                      style: AppTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style:
          AppTypography.body1.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline,
            color: AppColors.onSurfaceMuted),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFFE0D9FF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F5FF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Privacy & Security',
            style: AppTypography.heading3
                .copyWith(color: AppColors.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Profile Privacy'),
            const SizedBox(height: 12),
            _buildToggleCard(
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFEDE9FF),
              title: 'Public Profile',
              subtitle:
                  'Allow other community members to see your profile',
              value: _profileVisible,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _profileVisible = v);
                _showSavedSnack();
              },
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              icon: Icons.book_outlined,
              iconColor: const Color(0xFF805AD5),
              iconBg: const Color(0xFFF3EEFF),
              title: 'Share Journal Insights',
              subtitle:
                  'Allow anonymised insights from your journal to improve Zenrova',
              value: _shareJournalInsights,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _shareJournalInsights = v);
                _showSavedSnack();
              },
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              icon: Icons.favorite_outline_rounded,
              iconColor: const Color(0xFFE53E3E),
              iconBg: const Color(0xFFFFF0F0),
              title: 'Share Mood Trends',
              subtitle:
                  'Allow anonymised mood data to be used for research',
              value: _shareMoodTrends,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _shareMoodTrends = v);
                _showSavedSnack();
              },
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              icon: Icons.analytics_outlined,
              iconColor: AppColors.secondary,
              iconBg: const Color(0xFFEEF8FF),
              title: 'Analytics',
              subtitle:
                  'Help us improve the app by sharing usage analytics',
              value: _analyticsEnabled,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _analyticsEnabled = v);
                _showSavedSnack();
              },
            ),

            const SizedBox(height: 28),

            _buildSectionHeader('Security'),
            const SizedBox(height: 12),
            _buildToggleCard(
              icon: Icons.fingerprint_rounded,
              iconColor: const Color(0xFF38A169),
              iconBg: const Color(0xFFEAF7EF),
              title: 'Biometric Lock',
              subtitle:
                  'Use fingerprint or face ID to unlock the app',
              value: _biometricLock,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _biometricLock = v);
                _showSavedSnack(
                    v ? 'Biometric lock enabled!' : 'Biometric lock disabled.');
              },
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              icon: Icons.security_rounded,
              iconColor: const Color(0xFFED8936),
              iconBg: const Color(0xFFFFF3E8),
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security to your account',
              value: _twoFactorEnabled,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _twoFactorEnabled = v);
                _showSavedSnack(
                    v ? '2FA enabled!' : '2FA disabled.');
              },
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.lock_reset_rounded,
              iconColor: AppColors.primary,
              iconBg: const Color(0xFFEDE9FF),
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: _showChangePasswordDialog,
            ),

            const SizedBox(height: 28),

            _buildSectionHeader('Data'),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.download_outlined,
              iconColor: AppColors.secondary,
              iconBg: const Color(0xFFEEF8FF),
              title: 'Download My Data',
              subtitle: 'Export all your journals, moods, and data',
              onTap: () => _showSavedSnack(
                  'Your data export has been requested. You\'ll receive an email shortly.'),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.error,
              iconBg: const Color(0xFFFFF0F0),
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and all data',
              onTap: _showDeleteAccountDialog,
              isDestructive: true,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style:
            AppTypography.heading4.copyWith(color: AppColors.onSurface));
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    style: AppTypography.body1.copyWith(
                        color: AppColors.onSurface,
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
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.3)
                : const Color(0xFFEDE9FF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
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
                      style: AppTypography.body1.copyWith(
                          color: isDestructive
                              ? AppColors.error
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.body2
                          .copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceMuted, size: 20),
          ],
        ),
      ),
    );
  }
}