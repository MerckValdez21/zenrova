import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/user_model.dart';
import '../shared/models/mood_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
