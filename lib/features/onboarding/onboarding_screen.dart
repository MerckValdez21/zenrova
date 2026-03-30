import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: AppStrings.onboarding1Title,
      subtitle: AppStrings.onboarding1Subtitle,
      icon: Icons.self_improvement_rounded,
      gradientColors: [Color(0xFF6A4BC4), Color(0xFF8E5BBF)],
      orbColor: Color(0xFF9B7FD4),
      accentColor: Color(0xFFFF7E6B),
      emoji: '🌸',
    ),
    _OnboardingData(
      title: AppStrings.onboarding2Title,
      subtitle: AppStrings.onboarding2Subtitle,
      icon: Icons.insights_rounded,
      gradientColors: [Color(0xFF2D9AD8), Color(0xFF5BB8F5)],
      orbColor: Color(0xFF5BB8F5),
      accentColor: Color(0xFFFFD166),
      emoji: '✨',
    ),
    _OnboardingData(
      title: AppStrings.onboarding3Title,
      subtitle: AppStrings.onboarding3Subtitle,
      icon: Icons.favorite_rounded,
      gradientColors: [Color(0xFF38A169), Color(0xFF68D391)],
      orbColor: Color(0xFF68D391),
      accentColor: Color(0xFFFC8181),
      emoji: '💚',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final data = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.gradientColors[0].withValues(alpha: 0.08),
                  data.gradientColors[1].withValues(alpha: 0.04),
                  AppColors.background,
                ],
              ),
            ),
          ),

          // Background decorative orbs
          Positioned(
            top: -40,
            right: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    data.orbColor.withValues(alpha: 0.2),
                    data.orbColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.25,
            left: -50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    data.accentColor.withValues(alpha: 0.12),
                    data.accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Zenrova wordmark
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'zen',
                              style: AppTypography.heading3.copyWith(
                                color: data.gradientColors[0],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'rova',
                              style: AppTypography.heading3.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onComplete,
                        child: Text(
                          AppStrings.skip,
                          style: AppTypography.buttonSmall.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], size);
                    },
                  ),
                ),

                // Bottom section
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
                  child: Column(
                    children: [
                      // Indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => _buildDot(i, data.gradientColors[0]),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // CTA Button
                      _buildNextButton(data),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingData data, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating illustration card
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: child,
            ),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: data.gradientColors,
                ),
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: data.gradientColors[0].withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(data.icon, color: Colors.white, size: 72),
                      const SizedBox(height: 8),
                      Text(data.emoji, style: const TextStyle(fontSize: 28)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 52),

          // Title
          Text(
            data.title,
            style: AppTypography.heading1.copyWith(
              color: AppColors.onSurface,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Subtitle
          Text(
            data.subtitle,
            style: AppTypography.body1.copyWith(
              color: AppColors.onSurfaceMuted,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color activeColor) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : const Color(0xFFD4CCF5),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  Widget _buildNextButton(_OnboardingData data) {
    final isLast = _currentPage == _pages.length - 1;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: data.gradientColors[0].withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLast ? AppStrings.getStarted : AppStrings.next,
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color orbColor;
  final Color accentColor;
  final String emoji;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.orbColor,
    required this.accentColor,
    required this.emoji,
  });
}
