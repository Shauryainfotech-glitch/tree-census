import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tree_provider.dart';
import '../../models/user.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    treeProvider.loadDemoData(); // Load demo data for now
    await treeProvider.getCurrentLocation();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(user),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(user),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(user),
      drawer: _buildDrawer(user),
    );
  }

  PreferredSizeWidget _buildAppBar(User user) {
    return AppBar(
      title: const Text(
        AppConstants.appName,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            _showNotifications();
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Profile Information'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(user.role.displayName, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Email: ' + (user.email ?? '-')),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: Implement profile edit navigation
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(User user) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab(user);
      case 1:
        return _buildTreesTab();
      case 2:
        return _buildSurveyTab();
      case 3:
        return _buildRequestsTab();
      default:
        return _buildDashboardTab(user);
    }
  }

  Widget _buildDashboardTab(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          _buildWelcomeCard(user),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          _buildQuickActions(user),
          
          const SizedBox(height: 16),
          
          // Statistics
          _buildStatistics(),
          
          const SizedBox(height: 16),
          
          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    user.role == UserRole.admin
                        ? Icons.admin_panel_settings
                        : user.role == UserRole.surveyor
                            ? Icons.assignment_ind
                            : Icons.person,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome ${user.name.isNotEmpty ? user.name : user.role.displayName}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        user.role.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getWelcomeMessage(user.role),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(User user) {
    final actions = _getQuickActions(user.role);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1, // changed from 1.5 to 1.1 for more height
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionCard(
                title: action['title'],
                icon: action['icon'],
                color: action['color'],
                onTap: action['onTap'],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),

              const SizedBox(height: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<TreeProvider>(
      builder: (context, treeProvider, child) {
        final stats = treeProvider.getTreeStatistics();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Trees',
                    value: stats['totalTrees'].toString(),
                    icon: Icons.park,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: _buildStatCard(
                    title: 'Heritage Trees',
                    value: stats['heritageTrees'].toString(),
                    icon: Icons.account_balance,
                    color: AppColors.heritage,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Healthy Trees',
                    value: stats['healthyTrees'].toString(),
                    icon: Icons.favorite,
                    color: AppColors.treeHealthy,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: _buildStatCard(
                    title: 'Health Rate',
                    value: '${stats['healthPercentage']}%',
                    icon: Icons.trending_up,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
                
                const Spacer(),
                
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Icon(
                    _getActivityIcon(index),
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                title: Text(_getActivityTitle(index)),
                subtitle: Text(_getActivitySubtitle(index)),
                trailing: Text(
                  _getActivityTime(index),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTreesTab() {
    return const Center(
      child: Text('Trees Tab - Navigate to Tree Search'),
    );
  }

  Widget _buildSurveyTab() {
    return const Center(
      child: Text('Survey Tab - Navigate to Field Survey'),
    );
  }

  Widget _buildRequestsTab() {
    return const Center(
      child: Text('Requests Tab - Navigate to Requests'),
    );
  }

  Widget _buildBottomNavigationBar(User user) {
    final items = _getBottomNavItems(user.role);
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: AppTheme.primaryGreen,
      unselectedItemColor: AppTheme.textSecondary,
      items: items,
    );
  }

  Widget _buildDrawer(User user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '-',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  user.name.isNotEmpty ? user.name : '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                Text(
                  user.role.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search Trees'),
            onTap: () {
              Navigator.pop(context);
              context.go('/trees');
            },
          ),
          
          if (user.role == UserRole.surveyor || user.role == UserRole.admin)
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Field Survey'),
              onTap: () {
                Navigator.pop(context);
                context.go('/survey');
              },
            ),
          
          ListTile(
            leading: const Icon(Icons.request_page),
            title: const Text('Requests'),
            onTap: () {
              Navigator.pop(context);
              context.go('/requests');
            },
          ),
          
          if (user.role == UserRole.admin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin');
              },
            ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to help
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // Close the drawer
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context, true);
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  String _getWelcomeMessage(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Manage the tree census system and oversee all operations.';
      case UserRole.surveyor:
        return 'Conduct field surveys and update tree information.';
      case UserRole.citizen:
        return 'Search for trees and submit requests for tree services.';
    }
  }

  List<Map<String, dynamic>> _getQuickActions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          {
            'title': 'View Dashboard',
            'icon': Icons.dashboard,
            'color': AppTheme.primaryGreen,
            'onTap': () => context.go('/dashboard'),
          },
          {
            'title': 'Manage Requests',
            'icon': Icons.approval,
            'color': AppTheme.warningOrange,
            'onTap': () => context.go('/admin'),
          },
          {
            'title': 'View Reports',
            'icon': Icons.analytics,
            'color': AppTheme.infoBlue,
            'onTap': () => context.go('/dashboard'),
          },
          {
            'title': 'User Management',
            'icon': Icons.people,
            'color': AppTheme.secondaryGreen,
            'onTap': () => context.go('/admin'),
          },
        ];
      case UserRole.surveyor:
        return [
          {
            'title': 'Start Survey',
            'icon': Icons.assignment,
            'color': AppTheme.primaryGreen,
            'onTap': () => context.go('/survey'),
          },
          {
            'title': 'Search Trees',
            'icon': Icons.search,
            'color': AppTheme.infoBlue,
            'onTap': () => context.go('/trees'),
          },
          {
            'title': 'My Surveys',
            'icon': Icons.history,
            'color': AppTheme.secondaryGreen,
            'onTap': () => context.go('/survey'),
          },
          {
            'title': 'Sync Data',
            'icon': Icons.sync,
            'color': AppTheme.warningOrange,
            'onTap': () => _syncData(),
          },
        ];
      case UserRole.citizen:
        return [
          {
            'title': 'Search Trees',
            'icon': Icons.search,
            'color': AppTheme.primaryGreen,
            'onTap': () => context.go('/trees'),
          },
          {
            'title': 'Submit Request',
            'icon': Icons.add_circle,
            'color': AppTheme.infoBlue,
            'onTap': () => context.go('/request-form'),
          },
          {
            'title': 'My Requests',
            'icon': Icons.list_alt,
            'color': AppTheme.secondaryGreen,
            'onTap': () => context.go('/requests'),
          },
          {
            'title': 'Nearby Trees',
            'icon': Icons.location_on,
            'color': AppTheme.warningOrange,
            'onTap': () => _findNearbyTrees(),
          },
        ];
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems(UserRole role) {
    final commonItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Trees',
      ),
    ];

    if (role == UserRole.surveyor || role == UserRole.admin) {
      commonItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Survey',
        ),
      );
    }

    commonItems.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.request_page),
        label: 'Requests',
      ),
    );

    return commonItems;
  }

  IconData _getActivityIcon(int index) {
    switch (index) {
      case 0:
        return Icons.add_circle;
      case 1:
        return Icons.edit;
      case 2:
        return Icons.approval;
      default:
        return Icons.info;
    }
  }

  String _getActivityTitle(int index) {
    switch (index) {
      case 0:
        return 'New tree added';
      case 1:
        return 'Tree information updated';
      case 2:
        return 'Request approved';
      default:
        return 'Activity';
    }
  }

  String _getActivitySubtitle(int index) {
    switch (index) {
      case 0:
        return 'Mango tree added in Ward 1';
      case 1:
        return 'Peepal tree health status updated';
      case 2:
        return 'Pruning request #123 approved';
      default:
        return 'Description';
    }
  }

  String _getActivityTime(int index) {
    switch (index) {
      case 0:
        return '2h ago';
      case 1:
        return '4h ago';
      case 2:
        return '1d ago';
      default:
        return 'Now';
    }
  }

  void _showNotifications() {
    // TODO: Implement notifications
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _syncData() {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    treeProvider.syncOfflineData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data sync initiated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _findNearbyTrees() {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    treeProvider.getCurrentLocation();
    context.go('/trees');
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
