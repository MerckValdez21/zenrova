# Firebase Real User Setup Guide for Zenrova

## Quick Setup for Real Users (5-10 minutes)

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `zenrova-app` (or your preferred name)
4. **Enable Google Analytics** (recommended)
5. Click **"Create project"**

### Step 2: Enable Authentication
1. In Firebase Console, go to **"Authentication"** 
2. Click **"Sign-in method"**
3. Enable **"Email/Password"** and set to **"Enabled"**
4. **Disable email verification** for testing (enable later for production)

### Step 3: Set Up Firestore Database
1. Go to **"Firestore Database"** 
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select your location (choose closest to your users)
5. Click **"Create database"**

### Step 4: Get Your Firebase Configuration
1. In Firebase Console, go to **"Project Settings"** (gear icon)
2. Under **"Your apps"**, click **"Web"** (if not already added)
3. Copy the configuration values
4. Update `lib/core/config/firebase_config.dart` with your real values:

```dart
return const FirebaseOptions(
  apiKey: 'YOUR_REAL_API_KEY',
  appId: 'YOUR_REAL_APP_ID', 
  messagingSenderId: 'YOUR_REAL_SENDER_ID',
  projectId: 'YOUR_REAL_PROJECT_ID',
  storageBucket: 'YOUR_REAL_STORAGE_BUCKET',
  authDomain: 'YOUR_REAL_AUTH_DOMAIN',
  measurementId: 'YOUR_REAL_MEASUREMENT_ID',
);
```

### Step 5: Set Up Firestore Security Rules
In Firestore Console, go to **"Rules"** and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can access their own mood entries
    match /moods/{moodId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Users can access their own journal entries
    match /journals/{journalId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Check-ins
    match /check_ins/{checkInId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Admin users can read all data
    match /{document=**} {
      allow read, write: if request.auth != null && 
        request.auth.token.email == 'admin@zenrova.com';
    }
  }
}
```

### Step 6: Create Admin User
1. In Firebase Console, go to **"Authentication"** 
2. Click **"Add user"**
3. Email: `admin@zenrova.com`
4. Password: `admin123`
5. Click **"Add user"**

### Step 7: Test Your App
```bash
flutter run
```

**Test Real Registration:**
1. Try registering with a real email (e.g., `test@gmail.com`)
2. Use any password (6+ characters)
3. Check if user appears in Firebase Console

**Test Real Sign-in:**
1. Use the email/password you just registered
2. Should successfully sign in

**Test Admin Access:**
1. Use `admin@zenrova.com` / `admin123`
2. Should access admin dashboard

## Troubleshooting

### "Firebase initialization failed"
- Check that all configuration values are correct
- Ensure your Firebase project is created
- Verify Email/Password authentication is enabled

### "Sign-in failed"
- Check authentication is enabled in Firebase Console
- Verify user exists in Authentication section
- Check Firestore security rules

### "Permission denied" errors
- Review Firestore security rules
- Ensure user is authenticated
- Check user ID matches document ID

## Production Considerations

1. **Enable email verification** in Authentication settings
2. **Update security rules** for production use
3. **Set up proper indexes** in Firestore
4. **Configure rate limiting** in Authentication
5. **Set up monitoring** and alerts

## Admin Features for Real Users

Once Firebase is configured, you'll have:
- **Real user registration** with email verification
- **Secure authentication** with Firebase Auth
- **Real-time data sync** with Firestore
- **Admin dashboard** for user management
- **Persistent data storage** in cloud database

The app is now ready for real users with real email addresses!
