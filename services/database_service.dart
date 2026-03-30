import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zenrova/shared/models/user_model.dart';
import 'package:zenrova/shared/models/mood_model.dart';

class DatabaseService {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _moodsCollection = FirebaseFirestore.instance.collection('moods');

  // User operations
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
    } on FirebaseException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } on FirebaseException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());
    } on FirebaseException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } on FirebaseException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  // Mood operations
  Future<void> createMood(MoodModel mood) async {
    try {
      await _moodsCollection.doc(mood.id).set(mood.toJson());
    } on FirebaseException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<List<MoodModel>> getUserMoods(String userId, {int limit = 50}) async {
    try {
      final query = await _moodsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return query.docs
          .map((doc) => MoodModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> updateMood(MoodModel mood) async {
    try {
      await _moodsCollection.doc(mood.id).update(mood.toJson());
    } on FirebaseException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Future<void> deleteMood(String moodId) async {
    try {
      await _moodsCollection.doc(moodId).delete();
    } on FirebaseException catch (e) {
      throw _getErrorMessage(e);
    }
  }

  Stream<List<MoodModel>> streamUserMoods(String userId) {
    return _moodsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MoodModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  String _getErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permission denied. You may not have the required permissions.';
      case 'not-found':
        return 'The requested document was not found.';
      case 'already-exists':
        return 'The document already exists.';
      case 'resource-exhausted':
        return 'Resource exhausted. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed due to a failed precondition.';
      case 'aborted':
        return 'The operation was aborted.';
      case 'out-of-range':
        return 'The operation attempted to access data outside the valid range.';
      case 'unimplemented':
        return 'The operation is not implemented or not supported.';
      case 'internal':
        return 'Internal server error.';
      case 'unavailable':
        return 'Service unavailable. Please try again later.';
      case 'data-loss':
        return 'Data loss occurred.';
      case 'unauthenticated':
        return 'You are not authenticated. Please sign in.';
      default:
        return e.message ?? 'An unknown database error occurred.';
    }
  }
}