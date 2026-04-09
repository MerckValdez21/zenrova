import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../shared/models/user_model.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic>? _adminStats;
  List<UserModel>? _users;
  List<Map<String, dynamic>>? _allJournalEntries;
  List<Map<String, dynamic>>? _allMoodEntries;
  List<Map<String, dynamic>>? _allCheckIns;
  List<Map<String, dynamic>>? _selectedUserEntries;
  UserModel? _selectedUser;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _firestoreService.getAdminStats(),
        _firestoreService.getAllUsers(),
        _firestoreService.getAllJournalEntries(),
        _firestoreService.getAllMoodEntries(),
        _firestoreService.getAllCheckIns(),
      ]);

      if (mounted) {
        setState(() {
          _adminStats = results[0] as Map<String, dynamic>;
          _users = results[1] as List<UserModel>;
          _allJournalEntries = results[2] as List<Map<String, dynamic>>;
          _allMoodEntries = results[3] as List<Map<String, dynamic>>;
          _allCheckIns = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading admin data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadUserEntries(UserModel user) async {
    setState(() {
      _isLoading = true;
      _selectedUser = user;
    });
    try {
      final entries =
          await _firestoreService.getUserJournalEntriesForAdmin(user.id);
      if (mounted) {
        setState(() {
          _selectedUserEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UserModel> get _filteredUsers {
    if (_users == null) return [];
    if (_searchQuery.isEmpty) return _users!;
    return _users!
        .where((u) =>
            u.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (!userProvider.isAdmin) {
      // Redirect to admin login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          );
        }
      });
      
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Admin Dashboard',
            style:
                AppTypography.heading3.copyWith(color: AppColors.onSurface)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: _loadAdminData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 18)),
            Tab(text: 'Users',    icon: Icon(Icons.people_outlined, size: 18)),
            Tab(text: 'Journals', icon: Icon(Icons.book_outlined, size: 18)),
            Tab(text: 'Moods',    icon: Icon(Icons.favorite_outlined, size: 18)),
            Tab(text: 'Check-ins',icon: Icon(Icons.checklist_rounded, size: 18)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildJournalsTab(),
                _buildMoodsTab(),
                _buildCheckInsTab(),
              ],
            ),
    );
  }

  // ── Overview ─────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    if (_adminStats == null) {
      return const Center(child: Text('No data available'));
    }
    final stats = _adminStats!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Statistics',
              style: AppTypography.heading4
                  .copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: _buildStatCard('Total Users',
                    '${stats['totalUsers'] ?? 0}', AppColors.primary)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('Admin Users',
                    '${stats['adminUsers'] ?? 0}', AppColors.secondary)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _buildStatCard('Total Journals',
                    '${stats['totalJournals'] ?? 0}', AppColors.success)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('Total Moods',
                    '${stats['totalMoods'] ?? 0}', AppColors.accent)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _buildStatCard('Daily Check-ins',
                    '${stats['totalCheckIns'] ?? 0}',
                    const Color(0xFF805AD5))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('This Week',
                    '${stats['recentJournals'] ?? 0}',
                    AppColors.primaryLight)),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTypography.heading2.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: AppTypography.body2
                  .copyWith(color: AppColors.onSurfaceMuted)),
        ],
      ),
    );
  }

  // ── Users ─────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, i) =>
                _buildUserCard(_filteredUsers[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFEDE9FF), width: 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor:
              user.isAdmin ? AppColors.primary : AppColors.secondary,
          child: user.avatarUrl != null
              ? ClipOval(
                  child: Image.network(user.avatarUrl!,
                      width: 40, height: 40, fit: BoxFit.cover))
              : Icon(Icons.person, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(user.displayName,
                    style: AppTypography.heading4
                        .copyWith(color: AppColors.onSurface))),
            if (user.isAdmin)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('ADMIN',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.primary)),
              ),
          ],
        ),
        subtitle: Text(user.email,
            style: AppTypography.body2
                .copyWith(color: AppColors.onSurfaceMuted)),
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: AppColors.primary),
          onPressed: () {
            _tabController.animateTo(2);
            _loadUserEntries(user);
          },
        ),
      ),
    );
  }

  // ── Journals ──────────────────────────────────────────────────────
  Widget _buildJournalsTab() {
    if (_selectedUser != null && _selectedUserEntries != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() {
                    _selectedUser = null;
                    _selectedUserEntries = null;
                  }),
                ),
                Expanded(
                  child: Text(
                    'Entries for ${_selectedUser!.displayName}',
                    style: AppTypography.heading4
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                Text('${_selectedUserEntries!.length} entries',
                    style: AppTypography.body2
                        .copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _selectedUserEntries!.length,
              itemBuilder: (context, i) =>
                  _buildJournalCard(_selectedUserEntries![i]),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allJournalEntries?.length ?? 0,
      itemBuilder: (context, i) =>
          _buildJournalCard(_allJournalEntries![i]),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> entry) {
    final createdAt = entry['createdAt'] as Timestamp?;
    final date = createdAt?.toDate() ?? DateTime.now();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFEDE9FF), width: 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry['title'] ?? 'Untitled',
              style: AppTypography.heading4
                  .copyWith(color: AppColors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(entry['content'] ?? '',
              style: AppTypography.body2
                  .copyWith(color: AppColors.onSurfaceMuted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTag(
                  'User: ${entry['userId'] ?? 'Unknown'}',
                  AppColors.primary),
              const Spacer(),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: AppTypography.caption
                    .copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Moods ─────────────────────────────────────────────────────────
  Widget _buildMoodsTab() {
    final entries = _allMoodEntries ?? [];
    if (entries.isEmpty) {
      return Center(
        child: Text('No mood entries yet.',
            style: AppTypography.body1
                .copyWith(color: AppColors.onSurfaceMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) => _buildMoodCard(entries[i]),
    );
  }

  Widget _buildMoodCard(Map<String, dynamic> entry) {
    final createdAt = entry['createdAt'] as Timestamp?;
    final date = createdAt?.toDate() ?? DateTime.now();
    final mood = entry['mood'] as String? ?? 'Unknown';
    final intensity = entry['intensity'] as int? ?? 0;
    final notes = entry['notes'] as String? ?? '';
    final userName = entry['userName'] as String? ?? 'Unknown';

    final moodColors = {
      'Happy': const Color(0xFF38A169),
      'Excited': const Color(0xFFED8936),
      'Calm': const Color(0xFF3182CE),
      'Anxious': const Color(0xFFD69E2E),
      'Sad': const Color(0xFF805AD5),
      'Angry': const Color(0xFFE53E3E),
    };
    final moodColor = moodColors[mood] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: moodColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(mood,
                    style: AppTypography.buttonSmall
                        .copyWith(color: moodColor)),
              ),
              const SizedBox(width: 8),
              Text('Intensity: $intensity/10',
                  style: AppTypography.body2
                      .copyWith(color: AppColors.onSurfaceMuted)),
              const Spacer(),
              Text('${date.day}/${date.month}/${date.year}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.onSurfaceMuted)),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(notes,
                style: AppTypography.body2
                    .copyWith(color: AppColors.onSurfaceMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          _buildTag('User: $userName', AppColors.secondary),
        ],
      ),
    );
  }

  // ── Daily Check-ins ───────────────────────────────────────────────
  Widget _buildCheckInsTab() {
    final entries = _allCheckIns ?? [];
    if (entries.isEmpty) {
      return Center(
        child: Text('No daily check-ins yet.',
            style: AppTypography.body1
                .copyWith(color: AppColors.onSurfaceMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) => _buildCheckInCard(entries[i]),
    );
  }

  Widget _buildCheckInCard(Map<String, dynamic> entry) {
    final createdAt = entry['createdAt'] as Timestamp?;
    final date = createdAt?.toDate() ?? DateTime.now();
    final mood = entry['mood'] as String? ?? 'Unknown';
    final userName = entry['userName'] as String? ?? 'Unknown';

    const moodEmojis = {
      'Great': '😄',
      'Good': '🙂',
      'Okay': '😐',
      'Low': '😔',
      'Rough': '😞',
    };
    final emoji = moodEmojis[mood] ?? '😶';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFEDE9FF), width: 1),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mood,
                    style: AppTypography.heading4
                        .copyWith(color: AppColors.onSurface)),
                Text('by $userName',
                    style: AppTypography.body2
                        .copyWith(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: AppTypography.caption
                .copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          Text(text, style: AppTypography.caption.copyWith(color: color)),
    );
  }
}