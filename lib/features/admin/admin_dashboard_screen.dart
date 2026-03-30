import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../shared/models/user_model.dart';

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
  List<Map<String, dynamic>>? _selectedUserEntries;
  UserModel? _selectedUser;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      ]);
      
      if (mounted) {
        setState(() {
          _adminStats = results[0] as Map<String, dynamic>;
          _users = results[1] as List<UserModel>;
          _allJournalEntries = results[2] as List<Map<String, dynamic>>;
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
    setState(() => _isLoading = true);
    _selectedUser = user;
    
    try {
      final entries = await _firestoreService.getUserJournalEntriesForAdmin(user.id);
      if (mounted) {
        setState(() {
          _selectedUserEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user entries: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<UserModel> get _filteredUsers {
    if (_users == null) return [];
    if (_searchQuery.isEmpty) return _users!;
    
    return _users!.where((user) =>
      user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      user.email.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // Check if user is admin
    if (!userProvider.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings_outlined, 
                   size: 80, color: AppColors.onSurfaceMuted),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: AppTypography.heading2.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'You need admin privileges to access this screen.',
                style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('Go Back', style: AppTypography.button),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: AppTypography.heading3.copyWith(color: AppColors.onSurface),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Users', icon: Icon(Icons.people_outlined)),
            Tab(text: 'Journals', icon: Icon(Icons.book_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildJournalsTab(),
              ],
            ),
    );
  }

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
          Text('Platform Statistics', style: AppTypography.heading4.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', stats['totalUsers'].toString(), AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Admin Users', stats['adminUsers'].toString(), AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Journals', stats['totalJournals'].toString(), AppColors.success)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Total Moods', stats['totalMoods'].toString(), AppColors.accent)),
            ],
          ),
          const SizedBox(height: 24),
          
          Text('Recent Activity (Last 7 Days)', style: AppTypography.heading4.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildStatCard('New Journals', stats['recentJournals'].toString(), AppColors.primaryLight)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('New Moods', stats['recentMoods'].toString(), AppColors.secondaryLight)),
            ],
          ),
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
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.heading2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              return _buildUserCard(user);
            },
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
        border: Border.all(color: const Color(0xFFEDE9FF), width: 1),
        boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: user.isAdmin ? AppColors.primary : AppColors.secondary,
          child: user.avatarUrl != null
              ? ClipOval(child: Image.network(user.avatarUrl!, width: 40, height: 40, fit: BoxFit.cover))
              : Icon(Icons.person, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: AppTypography.heading4.copyWith(color: AppColors.onSurface),
              ),
            ),
            if (user.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('ADMIN', style: AppTypography.caption.copyWith(color: AppColors.primary)),
              ),
          ],
        ),
        subtitle: Text(
          user.email,
          style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: AppColors.primary),
          onPressed: () {
            _tabController.animateTo(2); // Switch to journals tab
            _loadUserEntries(user);
          },
        ),
      ),
    );
  }

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
                    style: AppTypography.heading4.copyWith(color: AppColors.primary),
                  ),
                ),
                Text(
                  '${_selectedUserEntries!.length} entries',
                  style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _selectedUserEntries!.length,
              itemBuilder: (context, index) {
                final entry = _selectedUserEntries![index];
                return _buildJournalEntryCard(entry);
              },
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allJournalEntries?.length ?? 0,
      itemBuilder: (context, index) {
        final entry = _allJournalEntries![index];
        return _buildJournalEntryCard(entry);
      },
    );
  }

  Widget _buildJournalEntryCard(Map<String, dynamic> entry) {
    final createdAt = entry['createdAt'] as Timestamp?;
    final date = createdAt?.toDate() ?? DateTime.now();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE9FF), width: 1),
        boxShadow: [BoxShadow(color: AppColors.shadowSoft, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry['title'] ?? 'Untitled',
            style: AppTypography.heading4.copyWith(color: AppColors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            entry['content'] ?? '',
            style: AppTypography.body2.copyWith(color: AppColors.onSurfaceMuted),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'User: ${entry['userId'] ?? 'Unknown'}',
                  style: AppTypography.caption.copyWith(color: AppColors.primary),
                ),
              ),
              const Spacer(),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: AppTypography.caption.copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
