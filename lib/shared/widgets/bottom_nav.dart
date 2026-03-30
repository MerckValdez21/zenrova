import 'package:flutter/material.dart';
import 'package:zenrova/core/constants/app_strings.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: AppStrings.home,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sentiment_satisfied_outlined),
          activeIcon: Icon(Icons.sentiment_satisfied),
          label: AppStrings.mood,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book),
          label: AppStrings.journal,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.spa_outlined),
          activeIcon: Icon(Icons.spa),
          label: AppStrings.calm,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outlined),
          activeIcon: Icon(Icons.people),
          label: AppStrings.community,
        ),
      ],
    );
  }
}
