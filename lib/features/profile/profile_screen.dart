import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../auth/auth_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController =
        TextEditingController(text: userProvider.displayName);
    _emailController =
        TextEditingController(text: userProvider.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider =
        Provider.of<UserProvider>(context, listen: false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    // Simulate network save
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) Navigator.of(context).pop(); // close loading

    // Update display name in provider — reflects immediately app-wide
    userProvider.updateUser(displayName: _nameController.text.trim());

    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Profile updated successfully!'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

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
            title: Text('Profile',
                style: AppTypography.heading3
                    .copyWith(color: AppColors.onSurface)),
            actions: [
              TextButton(
                onPressed: _saveProfile,
                child: Text('Save',
                    style: AppTypography.button.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          // Use SingleChildScrollView to prevent overflow on small screens
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── Avatar ──────────────────────────────────────────
                Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.avatarUrl!,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 48),
                              ),
                            )
                          : const Icon(Icons.person_rounded,
                              color: Colors.white, size: 48),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        key: const ValueKey('avatar_camera_button'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Image picker coming soon!')),
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.shadowSoft,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              size: 16, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Name display (updates live)
                Text(
                  userProvider.displayName,
                  style: AppTypography.heading3
                      .copyWith(color: AppColors.onSurface),
                ),
                if (userProvider.email.isNotEmpty)
                  Text(
                    userProvider.email,
                    style: AppTypography.body2
                        .copyWith(color: AppColors.onSurfaceMuted),
                  ),

                if (userProvider.isAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('ADMIN',
                        style: AppTypography.label
                            .copyWith(color: Colors.white)),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Form ────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildProfileField(
                        controller: _nameController,
                        label: 'Display Name',
                        hint: 'Enter your name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (v.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Your email address',
                        icon: Icons.mail_outline_rounded,
                        enabled: false,
                        validator: null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Settings section ────────────────────────────────
                _buildSettingsSection(userProvider),

                const SizedBox(height: 24),

                // ── Logout ──────────────────────────────────────────
                _buildLogoutButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.body2.copyWith(
                color: AppColors.onSurface, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          style: AppTypography.body1.copyWith(
              color:
                  enabled ? AppColors.onSurface : AppColors.onSurfaceMuted),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon,
                color: enabled
                    ? AppColors.onSurfaceMuted
                    : AppColors.onSurfaceMuted.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppColors.onSurfaceMuted.withValues(alpha: 0.3))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppColors.onSurfaceMuted.withValues(alpha: 0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: AppColors.onSurfaceMuted.withValues(alpha: 0.2))),
            filled: true,
            fillColor:
                enabled ? Colors.white : AppColors.surfaceElevated,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(UserProvider userProvider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── Dark Mode Toggle ─────────────────────────────────────
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: userProvider.isDarkMode ? 'On' : 'Off',
            value: userProvider.isDarkMode,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              userProvider.setDarkMode(v);
            },
          ),
          _buildDivider(),

          // ── Notifications ────────────────────────────────────────
          _buildNavTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notifications',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationsScreen())),
          ),
          _buildDivider(),

          // ── Privacy ──────────────────────────────────────────────
          _buildNavTile(
            icon: Icons.lock_outline,
            title: 'Privacy & Security',
            subtitle: 'Manage privacy and security settings',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PrivacyScreen())),
          ),

          // ── Admin Dashboard (admin only) ─────────────────────────
          if (userProvider.isAdmin) ...[
            _buildDivider(),
            _buildNavTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin Dashboard',
              subtitle: 'Manage users and view analytics',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AdminDashboardScreen())),
            ),
          ],

          _buildDivider(),

          // ── Help & Support ───────────────────────────────────────
          _buildNavTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const HelpSupportScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.body1
                        .copyWith(color: AppColors.onSurface)),
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

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: AppTypography.body1.copyWith(color: AppColors.onSurface)),
      subtitle: Text(subtitle,
          style: AppTypography.body2
              .copyWith(color: AppColors.onSurfaceMuted)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: AppColors.onSurfaceMuted, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFEDE9FF)),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Logout'),
              content:
                  const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Provider.of<UserProvider>(context, listen: false)
                        .clearUser();
                    Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const AuthScreen(),
                        transitionsBuilder: (_, a, __, child) =>
                            FadeTransition(opacity: a, child: child),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text('Logout',
            style: AppTypography.button.copyWith(color: AppColors.error)),
      ),
    );
  }
}