import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/user_provider.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';

/// Zenrova App Root Widget
class ZenrovaApp extends StatelessWidget {
  const ZenrovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return MaterialApp(
          title: 'Zenrova',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: userProvider.themeMode,
          home: const MainNavigator(),
        );
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: () => setState(() => _showOnboarding = false),
      );
    }
    return const AuthScreen();
  }
}