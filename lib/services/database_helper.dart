import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for offline journal storage.
/// Works as a cache — Firestore is the source of truth,
/// but entries are also saved here so the app works offline.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zenrova.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE journal_entries (
        id         TEXT PRIMARY KEY,
        title      TEXT NOT NULL,
        content    TEXT NOT NULL,
        created_at TEXT NOT NULL,
        user_id    TEXT NOT NULL,
        synced     INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ── INSERT ──────────────────────────────────────────────────────

  /// Save a journal entry locally. Call this every time you save to Firestore.
  /// [synced] = 1 means it has been uploaded to Firestore already.
  Future<void> insertJournalEntry({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required String userId,
    int synced = 1,
  }) async {
    final db = await database;
    await db.insert(
      'journal_entries',
      {
        'id': id,
        'title': title,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'user_id': userId,
        'synced': synced,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── READ ────────────────────────────────────────────────────────

  /// Get all journal entries for a user, newest first.
  Future<List<Map<String, dynamic>>> getJournalEntries(String userId) async {
    final db = await database;
    return await db.query(
      'journal_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  /// Get entries that have NOT been synced to Firestore yet.
  /// Use this when the internet connection is restored.
  Future<List<Map<String, dynamic>>> getUnsyncedEntries(String userId) async {
    final db = await database;
    return await db.query(
      'journal_entries',
      where: 'user_id = ? AND synced = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  // ── UPDATE ──────────────────────────────────────────────────────

  /// Update an existing entry (e.g. after the user edits it).
  Future<void> updateJournalEntry({
    required String id,
    required String title,
    required String content,
    int synced = 1,
  }) async {
    final db = await database;
    await db.update(
      'journal_entries',
      {
        'title': title,
        'content': content,
        'synced': synced,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark an entry as synced after a successful Firestore upload.
  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'journal_entries',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── DELETE ──────────────────────────────────────────────────────

  /// Delete a single entry by ID.
  Future<void> deleteJournalEntry(String id) async {
    final db = await database;
    await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all local entries for a user (e.g. on logout).
  Future<void> clearUserEntries(String userId) async {
    final db = await database;
    await db.delete(
      'journal_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ── CLOSE ───────────────────────────────────────────────────────

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}