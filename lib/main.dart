import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/providers/user_provider.dart';
import 'core/config/firebase_config.dart';

/// Zenrova — Entry Point
/// "Your light through the dark."
///
/// This is the very first file Flutter runs.
/// Keep this file clean and minimal.
Future<void> main() async {
  // Required before using any Flutter services
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseConfig.initializeFirebase();
  } catch (e) {
    // Continue without Firebase if initialization fails
    debugPrint('Firebase initialization failed: $e');
  }

  // Lock the app to portrait mode (best for mental health apps)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set the status bar style (light icons on purple)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Launch the app
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const ZenrovaApp(),
    ),
  );
}
