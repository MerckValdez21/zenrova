// ─────────────────────────────────────────────────────────────────────────────
// FIRESTORE SERVICE ADDITIONS
// Add these methods to your existing FirestoreService class.
// File: lib/services/firestore_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// These are the NEW methods you need to add. Your existing methods stay as-is.

// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../shared/models/user_model.dart';

// Inside class FirestoreService {

  /// Save a mood entry to Firestore (called from MoodCompassScreen).
  /// Collection: 'mood_entries'
  Future<void> saveMoodEntry(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('mood_entries')
        .doc(data['id'] as String)
        .set(data);
  }

  /// Save a daily check-in entry (called from HomeScreen).
  /// Collection: 'check_ins'
  Future<void> saveCheckIn(Map<String, dynamic> data) async {
    final docRef =
        FirebaseFirestore.instance.collection('check_ins').doc();
    await docRef.set({...data, 'id': docRef.id});
  }

  /// Admin: get ALL mood entries across all users.
  Future<List<Map<String, dynamic>>> getAllMoodEntries() async {
    final snap = await FirebaseFirestore.instance
        .collection('mood_entries')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Admin: get ALL daily check-in entries across all users.
  Future<List<Map<String, dynamic>>> getAllCheckIns() async {
    final snap = await FirebaseFirestore.instance
        .collection('check_ins')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ── Also update getAdminStats to include check-in count ──────────────────

  /// Admin stats — add 'totalCheckIns' to your existing getAdminStats method:
  ///
  ///   final checkInsSnap = await FirebaseFirestore.instance
  ///       .collection('check_ins').count().get();
  ///
  ///   return {
  ///     ...existing fields...,
  ///     'totalCheckIns': checkInsSnap.count ?? 0,
  ///   };

// } // end of FirestoreService