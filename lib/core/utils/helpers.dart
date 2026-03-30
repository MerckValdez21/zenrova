import 'package:flutter/material.dart';

/// Helpers — Zenrova Utility Class
/// Stateless utility methods used across the app.
class Helpers {
  Helpers._(); // prevent instantiation

  // ── Date & Time ────────────────────────────────────────────────

  /// e.g. "Mar 16, 2026"
  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// e.g. "09:41"
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// e.g. "Today", "Yesterday", or "Mar 14"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return formatDate(date);
  }

  /// e.g. "Good morning", "Good afternoon", "Good evening"
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Validation ─────────────────────────────────────────────────

  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }

  static bool isValidPassword(String password) => password.length >= 8;

  static bool isNotEmpty(String value) => value.trim().isNotEmpty;

  // ── Text ───────────────────────────────────────────────────────

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  /// Capitalizes the first letter of each word.
  static String toTitleCase(String text) {
    return text.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Returns word count of a string.
  static int wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Returns reading time estimate (e.g. "2 min read").
  static String readingTime(String text) {
    final words = wordCount(text);
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }

  // ── UI ─────────────────────────────────────────────────────────

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? color,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color ?? const Color(0xFF1A1A2E),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showSuccessSnack(BuildContext context, String message) {
    showSnackBar(context, message,
        color: const Color(0xFF38A169),
        icon: Icons.check_circle_rounded);
  }

  static void showErrorSnack(BuildContext context, String message) {
    showSnackBar(context, message,
        color: const Color(0xFFE53E3E),
        icon: Icons.error_outline_rounded);
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text(message,
            style: const TextStyle(fontFamily: 'DMSans', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? const Color(0xFFE53E3E)
                  : const Color(0xFF7C5CBF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ── Math / Health ──────────────────────────────────────────────

  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  /// Clamps a value between min and max.
  static double clamp(double value, double min, double max) {
    return value.clamp(min, max);
  }
}
