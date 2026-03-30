# Admin User Functionality

This document describes the admin functionality added to the Zenrova app.

## Features

### 1. Admin Role Management
- Added `isAdmin` field to `UserModel`
- Admin users can access special administrative features
- Role-based access control throughout the app

### 2. Admin Dashboard
The admin dashboard provides three main tabs:

#### Overview Tab
- Platform statistics (total users, admin users, total journals, total moods)
- Recent activity tracking (last 7 days)
- Visual analytics with colored stat cards

#### Users Tab
- View all registered users
- Search users by name or email
- Identify admin users with special badges
- View individual user journal entries

#### Journals Tab
- View all journal entries from all users
- Filter entries by specific user
- Entry details include title, content, user ID, and date

### 3. Admin Access Methods

#### Method 1: Profile Settings
1. Go to Profile screen
2. Scroll to Settings section
3. Click on "Admin Login" (for non-admin users) or "Admin Dashboard" (for admin users)

#### Method 2: Home Screen Button (Admins Only)
- Admin users see an admin button in the header
- Quick access to admin dashboard

### 4. Admin Login (Demo)
For demo purposes, use these credentials:
- **Email**: admin@zenrova.com
- **Password**: admin123

### 5. Firestore Integration
- All journal entries are now saved to Firestore
- Each entry includes user ID for tracking
- Admin can view entries from all users
- Real-time data synchronization

## Database Schema

### Users Collection
```dart
{
  'id': String,
  'email': String,
  'displayName': String,
  'avatarUrl': String?,
  'createdAt': DateTime,
  'lastLoginAt': DateTime,
  'isEmailVerified': bool,
  'isAdmin': bool,  // New field
}
```

### Journals Collection
```dart
{
  'id': String,
  'title': String,
  'content': String,
  'createdAt': Timestamp,
  'userId': String,  // Links to user
}
```

## Security Considerations

⚠️ **Important**: This is a demo implementation. For production:

1. Implement proper Firebase Security Rules
2. Use Firebase Auth custom claims for admin roles
3. Add proper authentication middleware
4. Implement audit logging for admin actions
5. Add rate limiting for admin operations

## Usage Instructions

### For Regular Users:
- Use the app normally - no changes to existing functionality
- Admin features are hidden unless logged in as admin

### For Admin Users:
1. Login with admin credentials
2. Access admin dashboard via profile settings or home button
3. Monitor platform usage and user activity
4. View individual user journal entries for support purposes

## Files Modified/Added

### New Files:
- `lib/features/admin/admin_dashboard_screen.dart` - Main admin interface
- `lib/features/admin/admin_login_screen.dart` - Admin login screen
- `ADMIN_FEATURES.md` - This documentation

### Modified Files:
- `lib/shared/models/user_model.dart` - Added isAdmin field
- `lib/core/providers/user_provider.dart` - Admin role management
- `lib/services/firestore_service.dart` - Admin-specific methods
- `lib/features/journal/journal_screen.dart` - Firestore integration
- `lib/features/home/home_screen.dart` - Admin button
- `lib/features/profile/profile_screen.dart` - Admin access
- `pubspec.yaml` - Added uuid dependency

## Testing

1. Run the app: `flutter run`
2. Navigate to Profile → Settings → Admin Login
3. Use demo credentials to login as admin
4. Explore the admin dashboard features
5. Test creating journal entries and viewing them in admin dashboard

## Future Enhancements

- [ ] User management (suspend/delete users)
- [ ] Export data functionality
- [ ] Advanced analytics and reporting
- [ ] Admin activity logging
- [ ] Bulk operations on user data
- [ ] Real-time notifications for admin actions
