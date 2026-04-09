import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/helpers.dart';
import '../profile/profile_screen.dart';
import '../mood/mood_compass_screen.dart';
import '../journal/journal_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  int? _selectedMood;
  bool _checkInSaved = false;
  final FirestoreService _firestoreService = FirestoreService();

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded,           label: AppStrings.home),
    _NavItem(icon: Icons.favorite_rounded,       label: AppStrings.mood),
    _NavItem(icon: Icons.book_rounded,           label: AppStrings.journal),
    _NavItem(icon: Icons.self_improvement_rounded, label: AppStrings.calm),
    _NavItem(icon: Icons.people_rounded,         label: AppStrings.community),
  ];

  final List<_MoodItem> _moods = [
    _MoodItem('😄', 'Great',  const Color(0xFF68D391)),
    _MoodItem('🙂', 'Good',   const Color(0xFF5BB8F5)),
    _MoodItem('😐', 'Okay',   const Color(0xFFFFD166)),
    _MoodItem('😔', 'Low',    const Color(0xFFFC8181)),
    _MoodItem('😞', 'Rough',  const Color(0xFFB794F4)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildMoodCheckin()),
          SliverToBoxAdapter(child: _buildQuickStats()),
          SliverToBoxAdapter(child: _buildSuggestedSection()),
          SliverToBoxAdapter(child: _buildBreathingCard()),
          // Extra bottom padding so content clears the floating nav bar
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 100,
            ),
          ),
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
                      Helpers.getGreeting(),
                      style: AppTypography.body1
                          .copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    Text(
                      '${userProvider.displayName} 👋',
                      style: AppTypography.heading2
                          .copyWith(color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (userProvider.isAdmin) ...[
                _buildAdminButton(),
                const SizedBox(width: 10),
              ],
              _buildIconButton(
                Icons.notifications_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ProfileScreen()),
                ),
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
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 22),
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

  Widget _buildIconButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
      ),
    );
  }

  Widget _buildAdminButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AdminDashboardScreen(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
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
        child: const Icon(Icons.admin_panel_settings_rounded,
            color: Colors.white, size: 20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        color: Colors.white, letterSpacing: 1.0),
                  ),
                ),
                if (_checkInSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text('Saved',
                            style: AppTypography.caption
                                .copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.howAreYouFeeling,
              style: AppTypography.heading3
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Mood buttons — no overflow on narrow screens
            LayoutBuilder(
              builder: (context, constraints) {
                final btnWidth =
                    (constraints.maxWidth - 4 * 8) / 5;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _moods.length,
                    (i) => SizedBox(
                      width: btnWidth,
                      child: _buildMoodButton(i),
                    ),
                  ),
                );
              },
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
        setState(() {
          _selectedMood = index;
          _checkInSaved = false;
        });
        _saveCheckIn(mood);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mood.emoji,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              mood.label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCheckIn(_MoodItem mood) async {
    final userProvider =
        Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? 'guest';
    final userName = userProvider.displayName;

    try {
      await _firestoreService.saveCheckIn({
        'userId': userId,
        'userName': userName,
        'mood': mood.label,
        'emoji': mood.emoji,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      if (mounted) {
        setState(() => _checkInSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Text('${mood.emoji} ',
                  style: const TextStyle(fontSize: 18)),
              Flexible(
                child: Text(
                  'Feeling ${mood.label.toLowerCase()} — logged!',
                  style: AppTypography.body2
                      .copyWith(color: Colors.white),
                ),
              ),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Silently fail — not critical
      debugPrint('Check-in save failed: $e');
    }
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(value,
              style: AppTypography.heading2.copyWith(color: color)),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.onSurfaceMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSuggestedSection() {
    final suggestions = [
      _SuggestionCard('Morning Gratitude', '5 min · Journal',
          Icons.book_outlined,
          const [Color(0xFF6A4BC4), Color(0xFF9B7FD4)]),
      _SuggestionCard('Box Breathing', '4 min · Calm',
          Icons.air_rounded,
          const [Color(0xFF2D9AD8), Color(0xFF5BB8F5)]),
      _SuggestionCard('Evening Reflection', '8 min · Journal',
          Icons.nights_stay_outlined,
          const [Color(0xFF38A169), Color(0xFF68D391)]),
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
                Text(AppStrings.suggested,
                    style: AppTypography.heading4
                        .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                TextButton(
                  onPressed: () {},
                  child: Text('See all',
                      style: AppTypography.buttonSmall
                          .copyWith(color: AppColors.primary)),
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
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) =>
                  _buildSuggestionCard(suggestions[i]),
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
        if (card.title.contains('Journal') ||
            card.title.contains('Gratitude') ||
            card.title.contains('Reflection')) {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const JournalScreen(),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
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
              child:
                  Icon(card.icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.title,
                    style: AppTypography.heading4
                        .copyWith(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(card.subtitle,
                    style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8))),
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFFEDE9FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 20,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2D9AD8), Color(0xFF5BB8F5)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.air_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Breathe',
                        style: AppTypography.heading4
                            .copyWith(color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text('A 1-minute reset, anytime.',
                        style: AppTypography.body2
                            .copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
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
                child: const Icon(Icons.play_arrow_rounded,
                    color: Color(0xFF2D9AD8), size: 22),
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
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              Text('Breathing Exercise',
                  style: AppTypography.heading3
                      .copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text('Coming soon! 🧘‍♀️',
                  style: AppTypography.body1.copyWith(
                      color: Colors.white.withValues(alpha: 0.9)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    Text('Got it!', style: AppTypography.button),
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
          20, 0, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
        switch (index) {
          case 0:
            setState(() => _selectedNavIndex = 0);
            break;
          case 1:
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MoodCompassScreen(),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 400),
            ));
            break;
          case 2:
            Navigator.of(context).push(PageRouteBuilder(
              pageBuilder: (_, __, ___) => const JournalScreen(),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 400),
            ));
            break;
          case 3:
          case 4:
            setState(() => _selectedNavIndex = index);
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 20,
                color: isSelected ? Colors.white : AppColors.onSurfaceMuted),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(item.label,
                  style: AppTypography.buttonSmall.copyWith(
                      color: Colors.white, fontSize: 11)),
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
  const _SuggestionCard(
      this.title, this.subtitle, this.icon, this.gradientColors);
}