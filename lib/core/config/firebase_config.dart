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

// Firebase configuration for real users
// Replace these values with your actual Firebase project credentials
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // TODO: Replace with your actual Firebase project values
    // Get these from your Firebase Console > Project Settings > General
    return const FirebaseOptions(
      apiKey: 'AIzaSyCvOQZ-NDcIdmPSc6MGSfkDrK1lQYWCyF8', // Replace with your API key
      appId: '1:204314257371:android:2ca9ec469026404c7769fe', // Replace with your App ID
      messagingSenderId: '204314257371', // Replace with your Sender ID
      projectId: 'zenrova-app', // Replace with your Project ID
      storageBucket: 'zenrova-app.appspot.com', // Replace with your Storage Bucket
      authDomain: 'zenrova-app.firebaseapp.com', // Replace with your Auth Domain
      measurementId: 'G-528599767', // Replace with your Measurement ID
    );
  }
}
