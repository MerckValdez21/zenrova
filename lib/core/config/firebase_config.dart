import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
      }
      rethrow;
    }
  }
}

// You'll need to generate this file using FlutterFire CLI
// Run: flutterfire configure
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // These are placeholder values - you'll need to run flutterfire configure
    // to get your actual Firebase configuration
    return const FirebaseOptions(
      apiKey: 'your-api-key',
      appId: 'your-app-id',
      messagingSenderId: 'your-sender-id',
      projectId: 'your-project-id',
      storageBucket: 'your-storage-bucket',
      authDomain: 'your-auth-domain',
      measurementId: 'your-measurement-id',
    );
  }
}
