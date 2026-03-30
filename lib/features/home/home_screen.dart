import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/user_provider.dart';
import '../profile/profile_screen.dart';
import '../mood/mood_compass_screen.dart';
import '../journal/journal_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  int? _selectedMood;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: AppStrings.home),
    _NavItem(icon: Icons.favorite_rounded, label: AppStrings.mood),
    _NavItem(icon: Icons.book_rounded, label: AppStrings.journal),
    _NavItem(icon: Icons.self_improvement_rounded, label: AppStrings.calm),
    _NavItem(icon: Icons.people_rounded, label: AppStrings.community),
  ];

  final List<_MoodItem> _moods = [
    _MoodItem('😄', 'Great', Color(0xFF68D391)),
    _MoodItem('🙂', 'Good', Color(0xFF5BB8F5)),
    _MoodItem('😐', 'Okay', Color(0xFFFFD166)),
    _MoodItem('😔', 'Low', Color(0xFFFC8181)),
    _MoodItem('😞', 'Rough', Color(0xFFB794F4)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildMoodCheckin()),
          SliverToBoxAdapter(child: _buildQuickStats()),
          SliverToBoxAdapter(child: _buildSuggestedSection()),
          SliverToBoxAdapter(child: _buildBreathingCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              24, MediaQuery.of(context).padding.top + 16, 24, 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.goodMorning,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    Text(
                      '${userProvider.displayName} 👋',
                      style: AppTypography.heading2.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return Row(
                    children: [
                      if (userProvider.isAdmin)
                        _buildAdminButton(),
                      const SizedBox(width: 10),
                      _buildIconButton(Icons.notifications_outlined),
                      const SizedBox(width: 10),
                    ],
                  );
                },
              ),
              // Avatar (clickable for profile)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: userProvider.user?.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            userProvider.user!.avatarUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 22);
                            },
                          ),
                        )
                      : const Icon(Icons.person_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
      ),
      child: Icon(icon, color: AppColors.onSurface, size: 20),
    );
  }

  Widget _buildAdminButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AdminDashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildMoodCheckin() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Daily Check-in',
                    style: AppTypography.label.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.howAreYouFeeling,
              style: AppTypography.heading3.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                _moods.length,
                (i) => _buildMoodButton(i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodButton(int index) {
    final mood = _moods[index];
    final isSelected = _selectedMood == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedMood = index);
        
        // Show success message after selecting mood
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Text('${mood.emoji} ', style: const TextStyle(fontSize: 18)),
                    Text(
                      'Thanks for checking in! You\'re feeling ${mood.label.toLowerCase()}.',
                      style: AppTypography.body2.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              mood.label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
              child: _buildStatCard('🔥', '7', 'Day streak',
                  AppColors.accent, const Color(0xFFFFF0EE))),
          const SizedBox(width: 14),
          Expanded(
              child: _buildStatCard('🧘', '14', 'Sessions',
                  AppColors.secondary, const Color(0xFFEEF8FF))),
          const SizedBox(width: 14),
          Expanded(
              child: _buildStatCard('📓', '23', 'Entries',
                  AppColors.primaryLight, const Color(0xFFF0EEFF))),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String emoji, String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.heading2.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedSection() {
    final suggestions = [
      _SuggestionCard('Morning Gratitude', '5 min · Journal', Icons.book_outlined,
          [Color(0xFF6A4BC4), Color(0xFF9B7FD4)]),
      _SuggestionCard('Box Breathing', '4 min · Calm', Icons.air_rounded,
          [Color(0xFF2D9AD8), Color(0xFF5BB8F5)]),
      _SuggestionCard('Evening Reflection', '8 min · Journal', Icons.nights_stay_outlined,
          [Color(0xFF38A169), Color(0xFF68D391)]),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.suggested,
                  style: AppTypography.heading4.copyWith(
                      color: AppColors.onSurface),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('See all',
                      style: AppTypography.buttonSmall.copyWith(
                        color: AppColors.primary,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 24),
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _buildSuggestionCard(suggestions[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(_SuggestionCard card) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        
        // Navigate to appropriate screen based on card type
        if (card.title.contains('Journal') || card.title.contains('Gratitude') || card.title.contains('Reflection')) {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const JournalScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        } else {
          // Show placeholder for other features
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${card.title}...'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showFeaturePlaceholder(card.title);
            }
          });
        }
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: card.gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: card.gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(card.icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: AppTypography.heading4.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  card.subtitle,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _startBreathingExercise();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D9AD8), Color(0xFF5BB8F5)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.air_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Breathe',
                      style: AppTypography.heading4.copyWith(
                          color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A 1-minute reset, anytime.',
                      style: AppTypography.body2.copyWith(
                          color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF2D9AD8),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startBreathingExercise() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.air_rounded, color: Colors.white, size: 60),
              const SizedBox(height: 16),
              Text(
                'Breathing Exercise',
                style: AppTypography.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming soon! 🧘‍♀️',
                style: AppTypography.body1.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Got it!', style: AppTypography.button),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeaturePlaceholder(String featureName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.construction_rounded, 
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                featureName,
                style: AppTypography.heading3.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'This feature is coming soon! We\'re working hard to bring you the best wellness experience.',
                style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Excited!', style: AppTypography.button),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFEDE9FF), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _navItems.length,
            (i) => _buildNavItem(i),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedNavIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        
        // Handle navigation for different tabs
        switch (index) {
          case 0: // Home
            setState(() => _selectedNavIndex = index);
            break;
          case 1: // Mood
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const MoodCompassScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
            break;
          case 2: // Journal
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const JournalScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
            break;
          case 3: // Calm
            setState(() => _selectedNavIndex = index);
            // TODO: Navigate to Calm screen when implemented
            break;
          case 4: // Community
            setState(() => _selectedNavIndex = index);
            // TODO: Navigate to Community screen when implemented
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.onSurfaceMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                item.label,
                style: AppTypography.buttonSmall.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _MoodItem {
  final String emoji;
  final String label;
  final Color color;
  const _MoodItem(this.emoji, this.label, this.color);
}

class _SuggestionCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  const _SuggestionCard(this.title, this.subtitle, this.icon, this.gradientColors);
}
