import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/user_model.dart';
import '../shared/models/mood_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Demo mode for live presentation - disabled for real users
  static const bool _demoMode = false;
  
  // Collection references
  static final CollectionReference _usersCollection = _firestore.collection('users');
  static final CollectionReference _moodsCollection = _firestore.collection('moods');
  static final CollectionReference _journalsCollection = _firestore.collection('journals');
  
  // User operations
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      if (kDebugMode) print('Error creating user: $e');
      rethrow;
    }
  }
  
  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting user: $e');
      rethrow;
    }
  }
  
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());
    } catch (e) {
      if (kDebugMode) print('Error updating user: $e');
      rethrow;
    }
  }
  
  // Mood operations
  Future<void> saveMoodEntry(MoodModel mood) async {
    try {
      await _moodsCollection.doc(mood.id).set(mood.toJson());
    } catch (e) {
      if (kDebugMode) print('Error saving mood entry: $e');
      rethrow;
    }
  }
  
  Future<List<MoodModel>> getUserMoods(String userId, {int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _moodsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => MoodModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting user moods: $e');
      rethrow;
    }
  }
  
  Future<List<MoodModel>> getRecentMoods(String userId, {int days = 7}) async {
    try {
      DateTime cutoff = DateTime.now().subtract(Duration(days: days));
      QuerySnapshot snapshot = await _moodsCollection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => MoodModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting recent moods: $e');
      rethrow;
    }
  }
  
  // Journal operations
  Future<void> saveJournalEntry(Map<String, dynamic> entry) async {
    try {
      await _journalsCollection.doc(entry['id']).set(entry);
    } catch (e) {
      if (kDebugMode) print('Error saving journal entry: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserJournalEntries(String userId, {int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _journalsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting journal entries: $e');
      rethrow;
    }
  }
  
  // Analytics operations
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get mood statistics
      QuerySnapshot moodSnapshot = await _moodsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      List<MoodModel> moods = moodSnapshot.docs
          .map((doc) => MoodModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Calculate streak (consecutive days with mood entries)
      int streak = _calculateStreak(moods);
      
      // Get journal count
      QuerySnapshot journalSnapshot = await _journalsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      return {
        'moodCount': moods.length,
        'journalCount': journalSnapshot.docs.length,
        'streak': streak,
        'lastMood': moods.isNotEmpty ? moods.first.createdAt : null,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting user stats: $e');
      rethrow;
    }
  }
  
  int _calculateStreak(List<MoodModel> moods) {
    if (moods.isEmpty) return 0;
    
    // Sort by date
    moods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (int i = 0; i < moods.length; i++) {
      DateTime moodDate = DateTime(
        moods[i].createdAt.year,
        moods[i].createdAt.month,
        moods[i].createdAt.day,
      );
      DateTime checkDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day - i,
      );
      
      if (moodDate.isAtSameMomentAs(checkDate)) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  // Check-in operations
  Future<void> saveCheckIn(Map<String, dynamic> data) async {
    try {
      final docRef = _firestore.collection('check_ins').doc();
      await docRef.set({...data, 'id': docRef.id});
    } catch (e) {
      if (kDebugMode) print('Error saving check-in: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllCheckIns({int limit = 100}) async {
    // Demo mode - return sample check-ins
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      return [
        {
          'id': 'checkin_1',
          'userId': 'demo_john_demo_com',
          'userName': 'John Doe',
          'mood': 'Great',
          'sleep': '8 hours',
          'energy': 'High',
          'stress': 'Low',
          'notes': 'Excellent sleep last night, feeling energized',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        },
        {
          'id': 'checkin_2',
          'userId': 'demo_sarah_demo_com',
          'userName': 'Sarah Wilson',
          'mood': 'Good',
          'sleep': '7 hours',
          'energy': 'Medium',
          'stress': 'Medium',
          'notes': 'Busy day but managing well',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        },
        {
          'id': 'checkin_3',
          'userId': 'demo_mike_demo_com',
          'userName': 'Mike Johnson',
          'mood': 'Okay',
          'sleep': '6 hours',
          'energy': 'Low',
          'stress': 'High',
          'notes': 'Stressed about work deadline',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
        },
      ];
    }
    
    // Firebase mode (original code)
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('check_ins')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting all check-ins: $e');
      rethrow;
    }
  }

  // Delete operations
  Future<void> deleteMoodEntry(String moodId) async {
    try {
      await _moodsCollection.doc(moodId).delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting mood entry: $e');
      rethrow;
    }
  }
  
  Future<void> deleteJournalEntry(String journalId) async {
    try {
      await _journalsCollection.doc(journalId).delete();
    } catch (e) {
      if (kDebugMode) print('Error deleting journal entry: $e');
      rethrow;
    }
  }
  
  // Admin operations
  Future<List<UserModel>> getAllUsers() async {
    // Demo mode - return sample users for presentation
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      return [
        UserModel(
          id: 'demo_john_demo_com',
          email: 'john@demo.com',
          displayName: 'John Doe',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)),
          isEmailVerified: true,
          isAdmin: false,
        ),
        UserModel(
          id: 'demo_sarah_demo_com',
          email: 'sarah@demo.com',
          displayName: 'Sarah Wilson',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          lastLoginAt: DateTime.now().subtract(const Duration(minutes: 30)),
          isEmailVerified: true,
          isAdmin: false,
        ),
        UserModel(
          id: 'demo_mike_demo_com',
          email: 'mike@demo.com',
          displayName: 'Mike Johnson',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          lastLoginAt: DateTime.now().subtract(const Duration(days: 1)),
          isEmailVerified: true,
          isAdmin: false,
        ),
        UserModel(
          id: 'demo_admin_demo_com',
          email: 'admin@demo.com',
          displayName: 'Admin User',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          lastLoginAt: DateTime.now().subtract(const Duration(minutes: 15)),
          isEmailVerified: true,
          isAdmin: true,
        ),
      ];
    }
    
    // Firebase mode (original code)
    try {
      QuerySnapshot snapshot = await _usersCollection.get();
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting all users: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getAllJournalEntries({int limit = 100}) async {
    // Demo mode - return sample journal entries
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      return [
        {
          'id': 'journal_1',
          'userId': 'demo_john_demo_com',
          'userName': 'John Doe',
          'title': 'My Wellness Journey',
          'content': 'Today I started my mindfulness practice. It feels amazing to take a moment for myself and focus on my mental health. I\'ve been feeling stressed lately with work, but this app is helping me stay centered.',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        },
        {
          'id': 'journal_2',
          'userId': 'demo_sarah_demo_com',
          'userName': 'Sarah Wilson',
          'title': 'Gratitude Practice',
          'content': 'I\'m grateful for my family, my health, and the opportunity to grow every day. Practicing gratitude has really shifted my perspective and helped me appreciate the small things in life.',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 5))),
        },
        {
          'id': 'journal_3',
          'userId': 'demo_mike_demo_com',
          'userName': 'Mike Johnson',
          'title': 'Managing Anxiety',
          'content': 'Had a tough day with anxiety, but used the breathing exercises and felt much better. It\'s important to remember that it\'s okay to have bad days and that they will pass.',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        },
      ];
    }
    
    // Firebase mode (original code)
    try {
      QuerySnapshot snapshot = await _journalsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting all journal entries: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getAllMoodEntries({int limit = 100}) async {
    // Demo mode - return sample mood entries
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      return [
        {
          'id': 'mood_1',
          'userId': 'demo_john_demo_com',
          'userName': 'John Doe',
          'mood': 'Happy',
          'intensity': 8,
          'notes': 'Feeling great after my morning meditation session',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        },
        {
          'id': 'mood_2',
          'userId': 'demo_sarah_demo_com',
          'userName': 'Sarah Wilson',
          'mood': 'Calm',
          'intensity': 7,
          'notes': 'Peaceful evening with some light reading',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
        },
        {
          'id': 'mood_3',
          'userId': 'demo_mike_demo_com',
          'userName': 'Mike Johnson',
          'mood': 'Anxious',
          'intensity': 6,
          'notes': 'Work stress but managing with breathing exercises',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
        },
        {
          'id': 'mood_4',
          'userId': 'demo_john_demo_com',
          'userName': 'John Doe',
          'mood': 'Excited',
          'intensity': 9,
          'notes': 'Looking forward to the weekend plans!',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        },
      ];
    }
    
    // Firebase mode (original code)
    try {
      QuerySnapshot snapshot = await _moodsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting all mood entries: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserJournalEntriesForAdmin(String userId, {int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _journalsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting user journal entries for admin: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getAdminStats() async {
    // Demo mode - return sample statistics
    if (_demoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'totalUsers': 4,
        'adminUsers': 1,
        'regularUsers': 3,
        'totalJournals': 12,
        'totalMoods': 28,
        'totalCheckIns': 15,
        'recentJournals': 5,
        'recentMoods': 8,
        'lastUpdated': DateTime.now(),
      };
    }
    
    // Firebase mode (original code)
    try {
      // Get all users
      QuerySnapshot userSnapshot = await _usersCollection.get();
      List<UserModel> users = userSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Get all journal entries
      QuerySnapshot journalSnapshot = await _journalsCollection.get();
      
      // Get all mood entries
      QuerySnapshot moodSnapshot = await _moodsCollection.get();
      
      // Calculate stats
      int totalUsers = users.length;
      int adminUsers = users.where((u) => u.isAdmin).length;
      int totalJournals = journalSnapshot.docs.length;
      int totalMoods = moodSnapshot.docs.length;
      
      // Get recent activity (last 7 days)
      DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      QuerySnapshot recentJournals = await _journalsCollection
          .where('createdAt', isGreaterThanOrEqualTo: weekAgo)
          .get();
      
      QuerySnapshot recentMoods = await _moodsCollection
          .where('createdAt', isGreaterThanOrEqualTo: weekAgo)
          .get();
      
      return {
        'totalUsers': totalUsers,
        'adminUsers': adminUsers,
        'regularUsers': totalUsers - adminUsers,
        'totalJournals': totalJournals,
        'totalMoods': totalMoods,
        'recentJournals': recentJournals.docs.length,
        'recentMoods': recentMoods.docs.length,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      if (kDebugMode) print('Error getting admin stats: $e');
      rethrow;
    }
  }
}
