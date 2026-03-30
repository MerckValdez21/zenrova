# Firebase Setup Guide for Zenrova

This guide will help you set up Firebase for the Zenrova mental health app.

## Prerequisites
- Flutter SDK installed
- Firebase account (free tier is sufficient)
- Android Studio / Xcode for mobile development

## Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `zenrova-app`
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Add Firebase to Flutter App
1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. Configure Firebase for your project:
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project
   - Choose platforms (Android, iOS, Web, etc.)

## Step 3: Enable Authentication Methods
1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Enable the following providers:
   - **Email/Password**: Enable and set email verification to "disabled" for development
   - **Google**: Enable (requires SHA-1 fingerprint setup)
   - **Phone**: Enable (optional)

## Step 4: Configure Firestore Database
1. Go to "Firestore Database" → "Create database"
2. Choose "Start in test mode" (for development)
3. Select a location (choose closest to your users)
4. Create database

## Step 5: Set Up Security Rules
For development, use these basic rules in Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only access their own mood entries
    match /moods/{moodId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Users can only access their own journal entries
    match /journals/{journalId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

## Step 6: Update Firebase Configuration
After running `flutterfire configure`, the `lib/core/config/firebase_config.dart` file will be automatically updated with your project's configuration.

## Step 7: Test the Integration
1. Run your app:
   ```bash
   flutter run
   ```

2. Test authentication features:
   - Try creating a new account
   - Test sign in functionality
   - Test password reset

3. Test data persistence:
   - Create mood entries
   - Check if data appears in Firestore Console
   - Test journal entries

## Step 8: Production Considerations
For production deployment:

### Authentication
- Enable email verification
- Set up proper email templates
- Configure rate limiting

### Firestore
- Update security rules for production
- Set up indexes for complex queries
- Configure data retention policies

### Storage (if needed)
- Set up Firebase Storage for file uploads
- Configure storage security rules

## Troubleshooting

### Common Issues
1. **"Firebase initialization failed"**
   - Check if `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are properly placed
   - Ensure Firebase project is correctly configured

2. **Authentication errors**
   - Verify authentication methods are enabled in Firebase Console
   - Check security rules if getting permission denied errors

3. **Firestore permission denied**
   - Review and update security rules
   - Ensure user is authenticated before accessing data

### Debug Mode
The app includes debug logging. Check the console for detailed error messages.

## Next Steps
Once Firebase is properly configured:
1. Implement real-time data synchronization
2. Add push notifications for mood reminders
3. Set up cloud functions for data processing
4. Configure analytics for user behavior tracking

## Support
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/overview)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase Community](https://github.com/FirebaseExtended/flutterfire/issues)
