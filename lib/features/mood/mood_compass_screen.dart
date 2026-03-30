import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class MoodCompassScreen extends StatefulWidget {
  const MoodCompassScreen({super.key});

  @override
  State<MoodCompassScreen> createState() => _MoodCompassScreenState();
}

class _MoodCompassScreenState extends State<MoodCompassScreen>
    with TickerProviderStateMixin {
  int _selectedMood = -1;
  int _selectedIntensity = 5;
  bool _isSaving = false;
  final TextEditingController _notesController = TextEditingController();

  late AnimationController _headerAnimController;
  late Animation<double> _headerAnim;
  late List<AnimationController> _moodAnimControllers;

  final List<MoodOption> _moods = [
    MoodOption('Happy',   Icons.sentiment_very_satisfied_rounded, Color(0xFF38A169), Color(0xFFEAF7EF), Color(0xFFC6F0D6)),
    MoodOption('Excited', Icons.celebration_rounded,              Color(0xFFED8936), Color(0xFFFFF3E8), Color(0xFFFFDEB8)),
    MoodOption('Calm',    Icons.spa_rounded,                      Color(0xFF3182CE), Color(0xFFEBF4FF), Color(0xFFBEDAF8)),
    MoodOption('Anxious', Icons.psychology_rounded,               Color(0xFFD69E2E), Color(0xFFFFFBEB), Color(0xFFFDE68A)),
    MoodOption('Sad',     Icons.sentiment_dissatisfied_rounded,   Color(0xFF805AD5), Color(0xFFF3EEFF), Color(0xFFD9C7F8)),
    MoodOption('Angry',   Icons.local_fire_department_rounded,    Color(0xFFE53E3E), Color(0xFFFFF0F0), Color(0xFFFED7D7)),
  ];

  static const List<String> _intensityLabels = [
    '', 'Barely', 'Slight', 'Mild', 'Moderate', 'Noticeable',
    'Strong', 'Intense', 'Very intense', 'Overwhelming', 'Extreme',
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerAnim = CurvedAnimation(
        parent: _headerAnimController, curve: Curves.easeOutCubic);
    _headerAnimController.forward();

    _moodAnimControllers = List.generate(
      _moods.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 60),
      ),
    );
    for (int i = 0; i < _moodAnimControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 70), () {
        if (mounted) _moodAnimControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _headerAnimController.dispose();
    for (final c in _moodAnimControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBgOrbs(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildMoodGrid()),
                SliverToBoxAdapter(child: _buildIntensitySection()),
                SliverToBoxAdapter(child: _buildNotesSection()),
                SliverToBoxAdapter(child: _buildSaveButton()),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgOrbs() {
    return Stack(children: [
      Positioned(
        top: -60, right: -60,
        child: Container(
          width: 240, height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.primary.withValues(alpha: 0.14),
              Colors.transparent,
            ]),
          ),
        ),
      ),
      Positioned(
        bottom: 100, left: -50,
        child: Container(
          width: 180, height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.secondary.withValues(alpha: 0.12),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(_headerAnim),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
                        boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text('7 day streak', style: AppTypography.label.copyWith(color: Colors.white, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Greeting chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Mood Compass', style: AppTypography.overline.copyWith(color: AppColors.primary)),
              ),
              const SizedBox(height: 10),
              Text(
                'How are you\nfeeling right now?',
                style: AppTypography.heading1.copyWith(color: AppColors.onSurface, height: 1.15),
              ),
              const SizedBox(height: 10),
              Text(
                'Your emotions are valid. Let\'s check in.',
                style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select your mood', style: AppTypography.heading4.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemCount: _moods.length,
            itemBuilder: (context, i) => ScaleTransition(
              scale: CurvedAnimation(
                parent: _moodAnimControllers[i],
                curve: Curves.elasticOut,
              ),
              child: _buildMoodTile(i),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildMoodTile(int index) {
    final mood = _moods[index];
    final isSelected = _selectedMood == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedMood = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? mood.color : mood.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? mood.color : mood.borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: mood.color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: AppColors.shadowSoft, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 52 : 44,
              height: isSelected ? 52 : 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : mood.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(mood.icon, color: isSelected ? Colors.white : mood.color, size: isSelected ? 28 : 24),
            ),
            const SizedBox(height: 10),
            Text(
              mood.label,
              style: AppTypography.buttonSmall.copyWith(
                color: isSelected ? Colors.white : mood.color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 20, height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntensitySection() {
    final selectedMood = _selectedMood >= 0 ? _moods[_selectedMood] : null;
    final activeColor = selectedMood?.color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Intensity', style: AppTypography.heading4.copyWith(color: AppColors.onSurface)),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$_selectedIntensity / 10',
                    style: AppTypography.buttonSmall.copyWith(color: activeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _selectedIntensity > 0 ? _intensityLabels[_selectedIntensity] : 'Adjust the slider',
              style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 20),
            // Custom slider track with gradient
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbColor: activeColor,
                activeTrackColor: activeColor,
                inactiveTrackColor: activeColor.withValues(alpha: 0.18),
                overlayColor: activeColor.withValues(alpha: 0.14),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              ),
              child: Slider(
                value: _selectedIntensity.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) => setState(() => _selectedIntensity = v.round()),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Low', style: AppTypography.caption.copyWith(color: AppColors.onSurfaceMuted)),
                Text('High', style: AppTypography.caption.copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Notes', style: AppTypography.heading4.copyWith(color: AppColors.onSurface)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('optional', style: AppTypography.caption.copyWith(color: AppColors.onSurfaceMuted)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("What's on your mind?", style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted)),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: AppTypography.body1.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Any specific thoughts, situations, or things you noticed today...',
                hintStyle: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted.withValues(alpha: 0.7)),
                contentPadding: const EdgeInsets.all(16),
                filled: true,
                fillColor: const Color(0xFFF7F5FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEDE9FF), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _selectedMood >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: canSave ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: canSave ? AppColors.primaryGradient : null,
                color: canSave ? null : const Color(0xFFD4CCF5),
                boxShadow: canSave
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.38), blurRadius: 20, offset: const Offset(0, 8))]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: canSave && !_isSaving ? _saveMoodEntry : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 62),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: EdgeInsets.zero,
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 10),
                          Text('Save Mood Entry', style: AppTypography.button.copyWith(color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ),
          if (!canSave) ...[
            const SizedBox(height: 12),
            Text(
              'Select a mood above to save your entry',
              style: AppTypography.caption.copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveMoodEntry() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            '${_moods[_selectedMood].label} mood saved!',
            style: AppTypography.body2.copyWith(color: Colors.white),
          ),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.maybePop(context);
  }
}

class MoodOption {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  const MoodOption(this.label, this.icon, this.color, this.bgColor, this.borderColor);
}
