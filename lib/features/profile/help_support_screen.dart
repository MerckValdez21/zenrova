import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaq;

  final List<_FaqItem> _faqs = [
    _FaqItem(
      'How do I track my mood?',
      'Tap the Heart icon in the bottom navigation bar to open the Mood Compass. Select how you\'re feeling, adjust the intensity, add optional notes, and tap "Save Mood Entry".',
    ),
    _FaqItem(
      'Are my journal entries private?',
      'Yes! Your journal entries are private and stored securely. Only your account can access them unless you choose to share insights in your Privacy settings.',
    ),
    _FaqItem(
      'How do I change my display name?',
      'Go to your Profile (tap the avatar icon on the home screen), update the Display Name field, then tap "Save" in the top-right corner.',
    ),
    _FaqItem(
      'Can I use Zenrova offline?',
      'Yes! Journal entries are saved locally on your device first and automatically synced to the cloud when you\'re back online.',
    ),
    _FaqItem(
      'How do I reset my password?',
      'On the login screen, tap "Forgot Password?" and enter your email. You\'ll receive a reset link shortly.',
    ),
    _FaqItem(
      'How do I delete my account?',
      'Go to Profile → Privacy & Security → Delete Account. Note that this is permanent and cannot be undone.',
    ),
    _FaqItem(
      'How do I enable dark mode?',
      'Go to your Profile screen. In the Account Settings section, tap the Dark Mode toggle to switch between light and dark themes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Help & Support',
            style: AppTypography.heading3
                .copyWith(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  Text('How can we help?',
                      style: AppTypography.heading3
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    'Browse FAQs below or contact our support team directly.',
                    style: AppTypography.body2.copyWith(
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Contact options
            Text('Contact Support',
                style: AppTypography.heading4
                    .copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email_outlined,
                    label: 'Email Us',
                    subtitle: 'support@zenrova.com',
                    color: AppColors.primary,
                    bg: const Color(0xFFEDE9FF),
                    onTap: () => _showContactSheet('Email Support',
                        'support@zenrova.com'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Live Chat',
                    subtitle: 'Mon–Fri 9am–6pm',
                    color: AppColors.secondary,
                    bg: const Color(0xFFEEF8FF),
                    onTap: () => _showComingSoon('Live Chat'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _buildContactRow(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Message Admin',
              subtitle: 'Reach out directly to the admin team',
              color: const Color(0xFF38A169),
              bg: const Color(0xFFEAF7EF),
              onTap: () => _showContactSheet(
                  'Message Admin', 'admin@zenrova.com'),
            ),

            const SizedBox(height: 28),

            // FAQ
            Text('Frequently Asked Questions',
                style: AppTypography.heading4
                    .copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 14),

            ...List.generate(_faqs.length, (i) => _buildFaqTile(i)),

            const SizedBox(height: 28),

            // App version
            Center(
              child: Column(
                children: [
                  Text('Zenrova',
                      style: AppTypography.heading4
                          .copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 4),
                  Text('Version 1.0.0 · Build 2025.1',
                      style: AppTypography.body2
                          .copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 4),
                  Text('Your light through the dark.',
                      style: AppTypography.caption
                          .copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: AppTypography.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTypography.caption
                    .copyWith(color: AppColors.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.body1.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: AppTypography.body2
                          .copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(int index) {
    final faq = _faqs[index];
    final isExpanded = _expandedFaq == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFEDE9FF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() =>
              _expandedFaq = isExpanded ? null : index);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : const Color(0xFFF0EEFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.remove_rounded
                          : Icons.add_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(faq.question,
                        style: AppTypography.body1.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(faq.answer,
                      style: AppTypography.body2.copyWith(
                          color: AppColors.onSurfaceMuted,
                          height: 1.6)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showContactSheet(String title, String email) {
    final messageCtrl = TextEditingController();
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
          padding:
              const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
              Text(title,
                  style: AppTypography.heading3
                      .copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 6),
              Text('Sending to: $email',
                  style: AppTypography.body2
                      .copyWith(color: AppColors.onSurfaceMuted)),
              const SizedBox(height: 20),
              TextField(
                controller: messageCtrl,
                maxLines: 5,
                style: AppTypography.body1
                    .copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Describe your issue or question...',
                  hintStyle: AppTypography.body2.copyWith(
                      color: AppColors.onSurfaceMuted
                          .withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: const Color(0xFFF7F5FF),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFEDE9FF), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppColors.primaryGradient,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                      content: Text(
                          'Your message has been sent! We\'ll reply within 24–48 hours.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14)),
                  ),
                  child: Text('Send Message',
                      style: AppTypography.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature is coming soon!'),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}