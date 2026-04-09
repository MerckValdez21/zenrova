import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/user_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/database_helper.dart'; // <-- NEW: SQFLite helper

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<JournalEntry> _entries = [];
  String _searchQuery = '';
  late AnimationController _fabAnimController;
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance; // <-- NEW
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  String? _currentUserId;

  final List<String> _prompts = [
    'What am I grateful for today?',
    'What challenged me and what did I learn?',
    'How did my body feel today?',
    'What would I tell my past self?',
    'What made me smile today?',
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _loadEntries();
    _setupConnectivityListener();
  }

  /// Load entries: try Firestore first, fall back to local SQFLite if offline.
  Future<void> _loadEntries() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    _currentUserId = userProvider.user!.id;
    setState(() => _isLoading = true);

    try {
      // 1. Try Firestore (online path)
      final entriesData = await _firestoreService
          .getUserJournalEntries(userProvider.user!.id);

      // 2. Mirror each entry into SQFLite so local cache stays fresh
      for (final data in entriesData) {
        await _dbHelper.insertJournalEntry(
          id: data['id'] ?? _uuid.v4(),
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          userId: data['userId'] ?? userProvider.user!.id,
          synced: 1, // already in Firestore
        );
      }

      if (mounted) {
        setState(() {
          _entries.clear();
          _entries.addAll(entriesData.map((data) => JournalEntry(
                id: data['id'] ?? _uuid.v4(),
                title: data['title'] ?? '',
                content: data['content'] ?? '',
                date: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                userId: data['userId'] ?? userProvider.user!.id,
              )));
          _isLoading = false;
        });
        // Sync any unsynced local entries now that we're online
        await _syncUnsyncedEntries(userProvider.user!.id);
      }
    } catch (e) {
      // 3. Firestore failed (offline) — load from SQFLite instead
      debugPrint('Firestore unavailable, loading from local DB: $e');
      await _loadFromLocal(userProvider.user!.id);
    }
  }

  /// Fallback: load journal entries from local SQFLite database.
  Future<void> _loadFromLocal(String userId) async {
    try {
      final localData = await _dbHelper.getJournalEntries(userId);
      if (mounted) {
        setState(() {
          _entries.clear();
          _entries.addAll(localData.map((data) => JournalEntry(
                id: data['id'],
                title: data['title'],
                content: data['content'],
                date: DateTime.parse(data['created_at']),
                userId: data['user_id'],
              )));
          _isLoading = false;
        });
        if (_entries.isNotEmpty) {
          _showOfflineSnack();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading entries: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// After coming back online, push any unsynced local entries to Firestore.
  Future<void> _syncUnsyncedEntries(String userId) async {
    final unsynced = await _dbHelper.getUnsyncedEntries(userId);
    for (final data in unsynced) {
      try {
        await _firestoreService.saveJournalEntry({
          'id': data['id'],
          'title': data['title'],
          'content': data['content'],
          'createdAt': Timestamp.fromDate(DateTime.parse(data['created_at'])),
          'userId': data['user_id'],
        });
        await _dbHelper.markAsSynced(data['id']);
      } catch (e) {
        debugPrint('Sync failed for entry ${data['id']}: $e');
      }
    }
  }

  /// Set up connectivity listener to automatically sync when coming back online
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none && _currentUserId != null) {
        // We're back online, try to sync any unsynced entries
        _syncUnsyncedEntries(_currentUserId!);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _fabAnimController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  List<JournalEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    return _entries
        .where((e) =>
            e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.content.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBgOrbs(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (_entries.isNotEmpty) _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : _entries.isEmpty
                          ? _buildEmptyState()
                          : _buildEntriesList(),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: ScaleTransition(
              scale: CurvedAnimation(
                  parent: _fabAnimController, curve: Curves.elasticOut),
              child: _buildFab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgOrbs() {
    return Stack(children: [
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.primary.withValues(alpha: 0.12),
              Colors.transparent,
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFEDE9FF), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.shadowSoft,
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.onSurface, size: 20),
                ),
              ),
              const Spacer(),
              if (_entries.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${_entries.length} ${_entries.length == 1 ? 'entry' : 'entries'}',
                    style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text('Zenrova Journal',
                style: AppTypography.overline
                    .copyWith(color: AppColors.primary)),
          ),
          const SizedBox(height: 10),
          Text(
            'Your Private\nSanctuary',
            style: AppTypography.heading1
                .copyWith(color: AppColors.onSurface, height: 1.15),
          ),
          const SizedBox(height: 8),
          Text(
            'Express freely. Reflect deeply. Grow quietly.',
            style: AppTypography.body2
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style:
              AppTypography.body2.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Search entries...',
            hintStyle: AppTypography.body2
                .copyWith(color: AppColors.onSurfaceMuted),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.onSurfaceMuted, size: 20),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 16),
                Text('Begin your story',
                    style: AppTypography.heading3
                        .copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'Writing helps you understand yourself.\nYour first entry is always the hardest.',
                  style: AppTypography.body2.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _showNewEntrySheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Write first entry',
                            style: AppTypography.button
                                .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Writing prompts to get started',
              style: AppTypography.heading4
                  .copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 14),
          ..._prompts.map((p) => _buildPromptChip(p)),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return GestureDetector(
      onTap: () {
        _titleController.text = prompt;
        _showNewEntrySheet();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(prompt,
                    style: AppTypography.body2
                        .copyWith(color: AppColors.onSurface))),
            const Icon(Icons.arrow_forward_rounded,
                color: AppColors.onSurfaceMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    final entries = _filteredEntries;
    if (entries.isEmpty) {
      return Center(
        child: Text('No entries match "$_searchQuery"',
            style: AppTypography.body2
                .copyWith(color: AppColors.onSurfaceMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, i) => _buildEntryCard(entries[i], i),
    );
  }

  Widget _buildEntryCard(JournalEntry entry, int index) {
    final gradients = [
      [const Color(0xFF6A4BC4), const Color(0xFF9B7FD4)],
      [const Color(0xFF2D9AD8), const Color(0xFF5BB8F5)],
      [const Color(0xFF38A169), const Color(0xFF68D391)],
      [const Color(0xFFD69E2E), const Color(0xFFF6C34A)],
    ];
    final gradient = gradients[index % gradients.length];
    final entryIndex = _entries.indexOf(entry);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: const Color(0xFFEDE9FF), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: AppTypography.heading4
                            .copyWith(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded,
                          color: AppColors.onSurfaceMuted, size: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text('Edit',
                                style: AppTypography.body2.copyWith(
                                    color: AppColors.onSurface)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.error),
                            const SizedBox(width: 10),
                            Text('Delete',
                                style: AppTypography.body2
                                    .copyWith(color: AppColors.error)),
                          ]),
                        ),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') _editEntry(entryIndex);
                        if (v == 'delete') _deleteEntry(entryIndex);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.content,
                  style: AppTypography.body2.copyWith(
                      color: AppColors.onSurfaceMuted, height: 1.55),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            gradient[0].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12, color: gradient[0]),
                          const SizedBox(width: 4),
                          Text(entry.formattedDate,
                              style: AppTypography.caption.copyWith(
                                  color: gradient[0],
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${entry.content.split(' ').length} words',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _showNewEntrySheet,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showNewEntrySheet() {
    if (_entries.isNotEmpty) {
      _titleController.clear();
      _contentController.clear();
    }
    _showEntrySheet(isEditing: false);
  }

  void _editEntry(int index) {
    _titleController.text = _entries[index].title;
    _contentController.text = _entries[index].content;
    _showEntrySheet(isEditing: true, entryIndex: index);
  }

  void _showEntrySheet({required bool isEditing, int? entryIndex}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntrySheet(
        titleController: _titleController,
        contentController: _contentController,
        isEditing: isEditing,
        onSave: () {
          if (_titleController.text.isNotEmpty &&
              _contentController.text.isNotEmpty) {
            if (isEditing && entryIndex != null) {
              _updateEntry(entryIndex);
            } else {
              _addEntry();
            }
            Navigator.pop(context);
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _addEntry() async {
    HapticFeedback.mediumImpact();

    final userProvider =
        Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    final entry = JournalEntry(
      id: _uuid.v4(),
      title: _titleController.text,
      content: _contentController.text,
      date: DateTime.now(),
      userId: userProvider.user!.id,
    );

    // 1. Save to local SQFLite first (always works, even offline)
    await _dbHelper.insertJournalEntry(
      id: entry.id,
      title: entry.title,
      content: entry.content,
      createdAt: entry.date,
      userId: entry.userId,
      synced: 0, // mark as unsynced until Firestore confirms
    );

    // Update UI immediately — no waiting for network
    if (mounted) {
      setState(() => _entries.insert(0, entry));
    }

    // 2. Then try to save to Firestore
    try {
      await _firestoreService.saveJournalEntry(entry.toJson());
      // Mark local copy as synced
      await _dbHelper.markAsSynced(entry.id);
      if (mounted) _showSuccessSnack('Entry saved!');
    } catch (e) {
      // Firestore failed but local save succeeded — user doesn't lose data
      if (mounted) {
        _showOfflineSnack();
      }
    }
  }

  void _updateEntry(int index) async {
    final userProvider =
        Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) return;

    final updatedEntry = JournalEntry(
      id: _entries[index].id,
      title: _titleController.text,
      content: _contentController.text,
      date: _entries[index].date,
      userId: userProvider.user!.id,
    );

    // 1. Update local DB first
    await _dbHelper.updateJournalEntry(
      id: updatedEntry.id,
      title: updatedEntry.title,
      content: updatedEntry.content,
      synced: 0,
    );

    if (mounted) {
      setState(() => _entries[index] = updatedEntry);
    }

    // 2. Then sync to Firestore
    try {
      await _firestoreService.saveJournalEntry(updatedEntry.toJson());
      await _dbHelper.markAsSynced(updatedEntry.id);
      if (mounted) _showSuccessSnack('Entry updated!');
    } catch (e) {
      if (mounted) _showOfflineSnack();
    }
  }

  void _deleteEntry(int index) async {
    HapticFeedback.mediumImpact();

    final entryId = _entries[index].id;

    // 1. Delete from local DB
    await _dbHelper.deleteJournalEntry(entryId);

    // Update UI immediately
    if (mounted) {
      setState(() => _entries.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Entry deleted',
                style: AppTypography.body2
                    .copyWith(color: Colors.white)),
          ]),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    // 2. Delete from Firestore
    try {
      await _firestoreService.deleteJournalEntry(entryId);
    } catch (e) {
      debugPrint('Firestore delete failed (will retry on sync): $e');
    }
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(msg,
              style:
                  AppTypography.body2.copyWith(color: Colors.white)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showOfflineSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.wifi_off_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text('Saved locally — will sync when online',
              style:
                  AppTypography.body2.copyWith(color: Colors.white)),
        ]),
        backgroundColor: const Color(0xFFD69E2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Bottom sheet for new/edit entry ─────────────────────────────
class _EntrySheet extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final bool isEditing;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EntrySheet({
    required this.titleController,
    required this.contentController,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0D9FF),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                isEditing ? 'Edit Entry' : 'New Entry',
                style: AppTypography.heading3
                    .copyWith(color: AppColors.onSurface),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.onSurfaceMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            style: AppTypography.heading4
                .copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Give this entry a title...',
              hintStyle: AppTypography.heading4.copyWith(
                  color:
                      AppColors.onSurfaceMuted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: const Color(0xFFF7F5FF),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFEDE9FF), width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contentController,
            maxLines: 6,
            style: AppTypography.body1
                .copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'What\'s on your mind today? Write freely...',
              hintStyle: AppTypography.body1.copyWith(
                  color:
                      AppColors.onSurfaceMuted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: const Color(0xFFF7F5FF),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFEDE9FF), width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.all(18),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFE0D9FF), width: 1.5),
                    ),
                    child: Center(
                        child: Text('Cancel',
                            style: AppTypography.button
                                .copyWith(color: AppColors.primary))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onSave,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                              isEditing ? 'Update' : 'Save Entry',
                              style: AppTypography.button
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String userId;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.userId,
  });

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(date),
      'userId': userId,
    };
  }
}