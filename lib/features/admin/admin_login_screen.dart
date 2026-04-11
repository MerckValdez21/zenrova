import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/user_provider.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Credentials are checked but NOT displayed in the UI
  static const String _adminEmail = 'admin@zenrova.com';
  static const String _adminPassword = 'admin123';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.createAdminUser('Admin');
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      (route) => false,
    );
  }

  Future<void> _loginAsAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use real Firebase Admin authentication
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      // Try to sign in with admin credentials using Firebase Auth
      UserCredential result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        // Create admin user in UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.createAdminUser('Admin');
        
        _navigateToDashboard();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Admin user not found. Please check credentials.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format. Please check your email.';
          break;
        case 'user-disabled':
          errorMessage = 'Admin account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
      }
      
      _showError(errorMessage);
    } catch (e) {
      _showError('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D3748).withValues(alpha: 0.3) : const Color(0xFFEDE9FF), width: 1.5),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: Theme.of(context).colorScheme.onSurface, size: 20),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                width: 72,
                height: 72,
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
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Admin Login',
                style: AppTypography.heading1.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),

              const SizedBox(height: 8),

              Text(
                'Sign in to access administrative controls.',
                style: AppTypography.body2.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),

              const SizedBox(height: 40),

              // Email field
              _buildLabel('Admin Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.body1.copyWith(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Enter admin email',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D3748).withValues(alpha: 0.3) : const Color(0xFFE0D9FF), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A202C).withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
                ),
              ),

              const SizedBox(height: 20),

              _buildLabel('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTypography.body1.copyWith(color: Theme.of(context).colorScheme.onSurface),
                onSubmitted: (_) => _loginAsAdmin(),
                decoration: InputDecoration(
                  hintText: 'Enter admin password',
                  prefixIcon: Icon(Icons.lock_outline,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D3748).withValues(alpha: 0.3) : const Color(0xFFE0D9FF), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A202C).withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface,
                ),
              ),

              const SizedBox(height: 36),

              // Login button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginAsAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text('Login as Admin', style: AppTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
    );
  }
}