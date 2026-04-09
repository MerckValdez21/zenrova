import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../features/auth/auth_view_model.dart';
import '../home/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {

  // ── Tab state ──────────────────────────────────────────────────
  bool _isSignIn = true;

  // ── Form keys ──────────────────────────────────────────────────
  final _loginFormKey    = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // ── Text controllers ───────────────────────────────────────────
  final _loginEmailCtrl         = TextEditingController();
  final _loginPasswordCtrl      = TextEditingController();
  final _registerNameCtrl       = TextEditingController();
  final _registerEmailCtrl      = TextEditingController();
  final _registerPasswordCtrl   = TextEditingController();
  final _registerConfirmCtrl    = TextEditingController();

  // ── Google panel ───────────────────────────────────────────────
  final _googleEmailCtrl   = TextEditingController();
  final _googleFocusNode   = FocusNode();
  bool   _showGooglePanel  = false;
  bool   _googleEmailError = false;
  String _googleEmailErrText = '';
  bool   _isGoogleLoading  = false;

  // ── Visibility toggles ─────────────────────────────────────────
  bool _loginPassVisible    = false;
  bool _registerPassVisible = false;
  bool _registerConfVisible = false;

  // ── Additional auth features ───────────────────────────────────
  bool _rememberMe = false;

  // ── Loading ────────────────────────────────────────────────────
  bool _isLoading = false;

  // ── Animations ─────────────────────────────────────────────────
  late AnimationController _pageAnim;
  late Animation<double>   _pageFade;
  late Animation<Offset>   _pageSlide;

  late AnimationController _pillAnim;
  late Animation<double>   _pillPos;

  late AnimationController _googlePanelAnim;
  late Animation<double>   _googlePanel;

  @override
  void initState() {
    super.initState();

    _pageAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _pageFade  = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic));
    _pageAnim.forward();

    _pillAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pillPos  = CurvedAnimation(parent: _pillAnim, curve: Curves.easeInOutCubic);

    _googlePanelAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _googlePanel = CurvedAnimation(
        parent: _googlePanelAnim, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _registerNameCtrl.dispose();
    _registerEmailCtrl.dispose();
    _registerPasswordCtrl.dispose();
    _registerConfirmCtrl.dispose();
    _googleEmailCtrl.dispose();
    _googleFocusNode.dispose();
    _pageAnim.dispose();
    _pillAnim.dispose();
    _googlePanelAnim.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Guest Access ───────────────────────────────────────────────
  void _handleGuestAccess() {
    HapticFeedback.lightImpact();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.continueAsGuest(context);
    _showSuccessSnack('Welcome, Guest!');
    Future.delayed(const Duration(milliseconds: 500),
        () { if (mounted) _navigateToHome(); });
  }

  // ── Tab switch ─────────────────────────────────────────────────
  void _switchTab(bool toSignIn) {
    if (_isSignIn == toSignIn) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isSignIn        = toSignIn;
      _showGooglePanel = false;
      _googleEmailCtrl.clear();
      _googleEmailError = false;
    });
    toSignIn ? _pillAnim.reverse() : _pillAnim.forward();
    _googlePanelAnim.reverse();
    _pageAnim..reset()..forward();
  }

  // ── Login ──────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.signIn(
      context,
      _loginEmailCtrl.text.trim(),
      _loginPasswordCtrl.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _navigateToHome();
      } else {
        _showErrorSnack(authViewModel.errorMessage ?? 'Sign-in failed.');
      }
    }
  }

  // ── Register ───────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.register(
      context,
      _registerNameCtrl.text.trim(),
      _registerEmailCtrl.text.trim(),
      _registerPasswordCtrl.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessSnack('Account created! Please sign in.');
        _registerNameCtrl.clear();
        _registerEmailCtrl.clear();
        _registerPasswordCtrl.clear();
        _registerConfirmCtrl.clear();
        _switchTab(true);
      } else {
        _showErrorSnack(authViewModel.errorMessage ?? 'Registration failed.');
      }
    }
  }

  // ── Forgot Password ────────────────────────────────────────────
  Future<void> _handleForgotPassword() async {
    HapticFeedback.lightImpact();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password', style: AppTypography.heading4),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email and we\'ll send you instructions to reset your password.',
                style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!value.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTypography.button.copyWith(color: AppColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop();

              final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
              final success = await authViewModel.resetPassword(emailController.text.trim());

              if (mounted) {
                if (success) {
                  _showSuccessSnack('Reset link sent! Check your inbox.');
                } else {
                  _showErrorSnack(authViewModel.errorMessage ?? 'Could not send reset email.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Send', style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  // ── Google panel ───────────────────────────────────────────────
  void _toggleGooglePanel() {
    HapticFeedback.lightImpact();
    final opening = !_showGooglePanel;
    setState(() {
      _showGooglePanel  = opening;
      _googleEmailError = false;
      _googleEmailErrText = '';
    });
    if (opening) {
      _googlePanelAnim.forward();
      Future.delayed(const Duration(milliseconds: 360),
          () { if (mounted) _googleFocusNode.requestFocus(); });
    } else {
      _googlePanelAnim.reverse();
      _googleEmailCtrl.clear();
    }
  }

  Future<void> _handleGoogleContinue() async {
    final email = _googleEmailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _googleEmailError   = true;
        _googleEmailErrText = 'Please enter your email.';
      });
      return;
    }
    if (!email.contains('@')) {
      setState(() {
        _googleEmailError   = true;
        _googleEmailErrText = 'Please enter a valid email address.';
      });
      return;
    }
    setState(() { _googleEmailError = false; _isGoogleLoading = true; });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.signInWithGoogle(email);

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      _showSuccessSnack('Signed in with Google!');
      Future.delayed(const Duration(milliseconds: 500),
          () { if (mounted) _navigateToHome(); });
    } else {
      _showErrorSnack(authViewModel.errorMessage ?? 'Google sign-in failed.');
    }
  }

  // ── Snack bars ─────────────────────────────────────────────────
  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Flexible(child: Text(msg,
            style: AppTypography.body2.copyWith(color: Colors.white))),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Flexible(child: Text(msg,
            style: AppTypography.body2.copyWith(color: Colors.white))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        _buildBgOrbs(size),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _pageFade,
                  child: SlideTransition(
                    position: _pageSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(),
                        const SizedBox(height: 36),
                        _buildTabSwitcher(),
                        const SizedBox(height: 28),
                        _isSignIn ? _buildLoginForm() : _buildRegisterForm(),
                        const SizedBox(height: 28),
                        _buildDivider(),
                        const SizedBox(height: 20),
                        _buildGoogleButton(),
                        SizeTransition(
                          sizeFactor: _googlePanel,
                          axisAlignment: -1,
                          child: FadeTransition(
                            opacity: _googlePanel,
                            child: _buildGooglePanel(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildFacebookButton(),
                        const SizedBox(height: 24),
                        _buildGuestButton(),
                        const SizedBox(height: 32),
                        _buildToggleFooter(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── Background orbs ─────────────────────────────────────────────
  Widget _buildBgOrbs(Size size) {
    return Stack(children: [
      Positioned(
        top: -90, right: -70,
        child: Container(width: 300, height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.primary.withValues(alpha: 0.16), Colors.transparent,
            ]),
          ),
        ),
      ),
      Positioned(
        top: size.height * 0.42, left: -80,
        child: Container(width: 220, height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.secondary.withValues(alpha: 0.12), Colors.transparent,
            ]),
          ),
        ),
      ),
      Positioned(
        bottom: 60, right: -40,
        child: Container(width: 160, height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.accent.withValues(alpha: 0.10), Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  // ─── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(children: [
      Container(
        width: 82, height: 82,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.42),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(Icons.spa_rounded, color: Colors.white, size: 42),
      ),
      const SizedBox(height: 22),
      Text('Welcome Back',
          style: AppTypography.heading1.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        _isSignIn
            ? 'Sign in to continue your wellness journey'
            : 'Create your free Zenrova account today',
        style: AppTypography.body1.copyWith(color: AppColors.onSurfaceMuted),
        textAlign: TextAlign.center,
      ),
    ]);
  }

  // ─── Sliding pill tab switcher ────────────────────────────────────
  Widget _buildTabSwitcher() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3FF), width: 1.5),
        boxShadow: [BoxShadow(
            color: AppColors.shadowSoft, blurRadius: 10,
            offset: const Offset(0, 3))],
      ),
      child: Stack(children: [
        AnimatedBuilder(
          animation: _pillPos,
          builder: (context, child) => LayoutBuilder(
            builder: (context, constraints) {
              final half = constraints.maxWidth / 2;
              return Positioned(
                left: _pillPos.value * half,
                top: 4, bottom: 4, width: half,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                ),
              );
            },
          ),
        ),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => _switchTab(true),
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _pillPos,
              builder: (context, child) => Center(child: Text('Sign In',
                style: AppTypography.button.copyWith(
                  color: _pillPos.value < 0.5
                      ? Colors.white : AppColors.onSurfaceMuted,
                  fontSize: 15))),
            ),
          )),
          Expanded(child: GestureDetector(
            onTap: () => _switchTab(false),
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _pillPos,
              builder: (context, child) => Center(child: Text('Sign Up',
                style: AppTypography.button.copyWith(
                  color: _pillPos.value > 0.5
                      ? Colors.white : AppColors.onSurfaceMuted,
                  fontSize: 15))),
            ),
          )),
        ]),
      ]),
    );
  }

  // ─── Login form ───────────────────────────────────────────────────
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(children: [
        _buildFieldGroup(
          controller: _loginEmailCtrl,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your email';
            if (!v.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFieldGroup(
          controller: _loginPasswordCtrl,
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: !_loginPassVisible,
          onToggleObscure: () =>
              setState(() => _loginPassVisible = !_loginPassVisible),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter your password';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: _rememberMe ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _rememberMe ? AppColors.primary : const Color(0xFFD1D5DB),
                        width: 1.5,
                      ),
                    ),
                    child: _rememberMe
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text('Remember me',
                      style: AppTypography.body2.copyWith(
                          color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _handleForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Forgot Password?',
                  style: AppTypography.body2.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(label: 'Sign In', onPressed: _handleLogin),
      ]),
    );
  }

  // ─── Register form ────────────────────────────────────────────────
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(children: [
        _buildFieldGroup(
          controller: _registerNameCtrl,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your name';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFieldGroup(
          controller: _registerEmailCtrl,
          label: 'Email',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter your email';
            if (!v.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFieldGroup(
          controller: _registerPasswordCtrl,
          label: 'Password',
          hint: 'Create a password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: !_registerPassVisible,
          onToggleObscure: () =>
              setState(() => _registerPassVisible = !_registerPassVisible),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please enter a password';
            if (v.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildFieldGroup(
          controller: _registerConfirmCtrl,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscure: !_registerConfVisible,
          onToggleObscure: () =>
              setState(() => _registerConfVisible = !_registerConfVisible),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _registerPasswordCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Create Account', onPressed: _handleRegister),
      ]),
    );
  }

  // ─── Shared form field ────────────────────────────────────────────
  Widget _buildFieldGroup({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    bool hasError = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label,
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(
              color: hasError
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword ? obscure : false,
            keyboardType: keyboardType,
            focusNode: focusNode,
            validator: validator,
            style: AppTypography.input.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              enabledBorder: hasError
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: AppColors.error, width: 1.5))
                  : null,
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(icon, size: 20,
                    color: hasError
                        ? AppColors.error
                        : AppColors.onSurfaceMuted),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 52, minHeight: 52),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20, color: AppColors.onSurfaceMuted,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Primary gradient button ──────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.primaryGradient,
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.42),
          blurRadius: 22, offset: const Offset(0, 9))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          padding: EdgeInsets.zero,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style: AppTypography.button
                    .copyWith(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  // ─── Divider ──────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(children: [
      Expanded(child: Container(height: 1, color: const Color(0xFFE0D9FF))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Or continue with',
            style: AppTypography.caption.copyWith(
                color: AppColors.onSurfaceMuted, letterSpacing: 0.3)),
      ),
      Expanded(child: Container(height: 1, color: const Color(0xFFE0D9FF))),
    ]);
  }

  // ─── Google button ────────────────────────────────────────────────
  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _toggleGooglePanel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _showGooglePanel
                ? AppColors.primary : const Color(0xFFE0D9FF),
            width: _showGooglePanel ? 2.0 : 1.5,
          ),
          boxShadow: [BoxShadow(
            color: _showGooglePanel
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.shadowSoft,
            blurRadius: _showGooglePanel ? 18 : 10,
            offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleLogo(),
            const SizedBox(width: 12),
            Text('Continue with Google',
                style: AppTypography.button.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _showGooglePanel ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: _showGooglePanel
                      ? AppColors.primary : AppColors.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Google email panel ───────────────────────────────────────────
  Widget _buildGooglePanel() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
        boxShadow: [BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.07),
          blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _GoogleLogo(),
            const SizedBox(width: 10),
            Text('Sign in with Google',
                style: AppTypography.heading4
                    .copyWith(color: AppColors.onSurface)),
          ]),
          const SizedBox(height: 6),
          Text('Enter the email linked to your Google account.',
              style: AppTypography.body2
                  .copyWith(color: AppColors.onSurfaceMuted)),
          const SizedBox(height: 16),
          _buildGoogleEmailField(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _googleEmailError
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Flexible(child: Text(_googleEmailErrText,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.error))),
                    ]),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          _buildGoogleContinueButton(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE9FF), width: 1),
            ),
            child: Row(children: [
              Icon(Icons.lock_outline_rounded,
                  size: 15,
                  color: AppColors.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                  "We'll verify your Google account securely. Your data is safe.",
                  style: AppTypography.caption.copyWith(
                      color: AppColors.onSurfaceMuted, height: 1.45))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Email',
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(
              color: _googleEmailError
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: _googleEmailCtrl,
            focusNode: _googleFocusNode,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _handleGoogleContinue(),
            style: AppTypography.input.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'your@email.com',
              enabledBorder: _googleEmailError
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: AppColors.error, width: 1.5))
                  : null,
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.email_outlined, size: 20,
                    color: _googleEmailError
                        ? AppColors.error : AppColors.onSurfaceMuted),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 52, minHeight: 52),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleContinueButton() {
    return GestureDetector(
      onTap: _isGoogleLoading ? null : _handleGoogleContinue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: _isGoogleLoading
              ? AppColors.primary.withValues(alpha: 0.85)
              : const Color(0xFFF0ECFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isGoogleLoading
                ? AppColors.primary : const Color(0xFFE0D9FF),
            width: 1.5,
          ),
        ),
        child: Center(
          child: _isGoogleLoading
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white)),
                  const SizedBox(width: 12),
                  Text('Signing in…',
                      style: AppTypography.button
                          .copyWith(color: Colors.white, fontSize: 15)),
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const _GoogleLogo(),
                  const SizedBox(width: 10),
                  Text('Continue with Google',
                      style: AppTypography.button.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.primary),
                ]),
        ),
      ),
    );
  }

  // ─── Facebook button ──────────────────────────────────────────────
  Widget _buildFacebookButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D9FF), width: 1.5),
        boxShadow: [BoxShadow(
            color: AppColors.shadowSoft, blurRadius: 10,
            offset: const Offset(0, 3))],
      ),
      child: ElevatedButton(
        onPressed: () {
          _showErrorSnack('Facebook sign-in is not available yet.');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.onSurface,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text('f',
                    style: TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w800, height: 1.2)),
              ),
            ),
            const SizedBox(width: 12),
            Text('Continue with Facebook',
                style: AppTypography.button.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // ─── Guest button ─────────────────────────────────────────────────
  Widget _buildGuestButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3FF), width: 1.5),
        boxShadow: [BoxShadow(
          color: AppColors.shadowSoft,
          blurRadius: 10,
          offset: const Offset(0, 3),
        )],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleGuestAccess,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.person_outline_rounded,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Text('Continue as Guest',
                  style: AppTypography.button.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Footer toggle link ───────────────────────────────────────────
  Widget _buildToggleFooter() {
    return RichText(
      text: TextSpan(
        style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
        children: [
          TextSpan(
            text: _isSignIn
                ? "Don't have an account? "
                : 'Already have an account? ',
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _switchTab(!_isSignIn),
              child: Text(
                _isSignIn ? 'Create one' : 'Sign in',
                style: AppTypography.body2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google "G" logo ────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 22, height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()));
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const g = 0.05;
    _arc(canvas, c, r, -math.pi / 2 + g, math.pi / 2 - g * 2, const Color(0xFFEA4335));
    _arc(canvas, c, r,  g,               math.pi / 2 - g * 2, const Color(0xFFFBBC05));
    _arc(canvas, c, r,  math.pi / 2 + g, math.pi / 2 - g * 2, const Color(0xFF34A853));
    _arc(canvas, c, r,  math.pi + g,     math.pi / 2 - g * 2, const Color(0xFF4285F4));
    canvas.drawCircle(c, r * 0.55, Paint()..color = Colors.white);
    canvas.drawLine(
      Offset(size.width * 0.52, c.dy), Offset(size.width * 0.98, c.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = r * 0.38
        ..strokeCap = StrokeCap.round,
    );
  }

  void _arc(Canvas canvas, Offset c, double r, double s, double sw, Color color) {
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.72), s, sw, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.38
        ..strokeCap = StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}