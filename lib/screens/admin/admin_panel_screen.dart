import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tree_census/models/user.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../models/tree_request.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    
    dashboardProvider.loadDemoData();
    requestProvider.loadDemoData();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        elevation: 4,
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          overlayColor: MaterialStateProperty.all(Colors.transparent), // Remove blue hover
          indicator: BoxDecoration(
            // borderRadius: BorderRadius.circular(30),
            // color: AppTheme.accentBlue.withOpacity(0.7),
          ),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.assignment), text: 'Requests'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(isWide),
            _buildRequestsTab(isWide),
            _buildUsersTab(isWide),
            _buildReportsTab(isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminStatsCards(isWide),
          const SizedBox(height: 32),
          _buildUrgentActionsSection(isWide),
          const SizedBox(height: 32),
          _buildQuickActionsSection(isWide),
          const SizedBox(height: 32),
          _buildSystemStatusSection(isWide),
        ],
      ),
    );
  }

  Widget _buildAdminStatsCards(bool isWide) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        final stats = dashboardProvider.statistics;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isWide ? 1.7 : 0.8, // Lowered for small screens to prevent overflow
              children: [
                _buildStatCard(
                  'Total Trees',
                  stats['totalTrees']?.toString() ?? '0',
                  Icons.park,
                  AppTheme.primaryGreen,
                ),
                _buildStatCard(
                  'Pending Requests',
                  stats['pendingRequests']?.toString() ?? '0',
                  Icons.pending_actions,
                  AppTheme.warningOrange,
                ),
                _buildStatCard(
                  'Active Users',
                  stats['activeUsers']?.toString() ?? '0',
                  Icons.people,
                  AppTheme.accentBlue,
                ),
                _buildStatCard(
                  'Reports',
                  stats['reports']?.toString() ?? '0',
                  Icons.bar_chart,
                  AppTheme.primaryPurple,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentActionsSection(bool isWide) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        final urgentItems = dashboardProvider.getUrgentItems();
        
        if (urgentItems.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.priority_high, color: AppTheme.errorRed),
                const SizedBox(width: 8),
                Text(
                  'Urgent Actions Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Card(
              color: AppTheme.errorRed.withOpacity(0.1),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: urgentItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = urgentItems[index];
                  return ListTile(
                    leading: Icon(
                      _getUrgentItemIcon(item['icon']),
                      color: AppTheme.errorRed,
                    ),
                    title: Text(item['title']),
                    subtitle: Text(item['description']),
                    trailing: Chip(
                      label: Text(item['count'].toString()),
                      backgroundColor: AppTheme.errorRed.withOpacity(0.2),
                    ),
                    onTap: () => _handleUrgentAction(item),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2,
          children: [
            _buildActionCard(
              'Approve Requests',
              Icons.approval,
              AppTheme.successGreen,
              () => _navigateToRequests(),
            ),
            _buildActionCard(
              'Manage Users',
              Icons.people_alt,
              AppTheme.infoBlue,
              () => _manageUsers(),
            ),
            _buildActionCard(
              'Generate Reports',
              Icons.analytics,
              AppTheme.primaryGreen,
              () => _generateReports(),
            ),
            _buildActionCard(
              'System Settings',
              Icons.settings,
              AppTheme.textSecondary,
              () => _showSettings(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatusSection(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Status',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusRow('Database', true, 'Connected'),
                _buildStatusRow('API Services', true, 'Running'),
                _buildStatusRow('AI Services', false, 'Maintenance'),
                _buildStatusRow('File Storage', true, 'Available'),
                _buildStatusRow('Backup System', true, 'Last: 2 hours ago'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String service, bool isHealthy, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.warning,
            color: isHealthy ? AppTheme.successGreen : AppTheme.warningOrange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isHealthy ? AppTheme.successGreen : AppTheme.warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(bool isWide) {
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, child) {
        final pendingRequests = requestProvider.getRequestsByStatus(RequestStatus.pending);
        final statistics = requestProvider.getRequestStatistics();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildRequestStatCard(
                      'Pending',
                      pendingRequests.length.toString(),
                      AppColors.requestPending,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRequestStatCard(
                      'This Month',
                      statistics['totalRequests']?.toString() ?? '0',
                      AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Pending Requests List
              Text(
                'Pending Requests',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (pendingRequests.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: AppTheme.successGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No pending requests',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Text('All requests have been processed'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.requestPending.withOpacity(0.2),
                          child: Icon(
                            Icons.pending_actions,
                            color: AppColors.requestPending,
                          ),
                        ),
                        title: Text(request.requestType.displayName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('By: ${request.applicantName}'),
                            Text('Submitted: ${_formatDate(request.submissionDate)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: AppTheme.errorRed),
                              onPressed: () => _rejectRequest(request),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: AppTheme.successGreen),
                              onPressed: () => _approveRequest(request),
                            ),
                          ],
                        ),
                        onTap: () => _viewRequestDetails(request),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(bool isWide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Management Header
          Row(
            children: [
              Text(
                'User Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addNewUser,
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User Statistics
          Row(
            children: [
              Expanded(
                child: _buildUserStatCard('Total Users', '45', Icons.people),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUserStatCard('Active Surveyors', '12', Icons.assignment_ind),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUserStatCard('Admins', '3', Icons.admin_panel_settings),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Users List
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text('A', style: TextStyle(color: Colors.white)),
                  ),
                  title: const Text('Admin User'),
                  subtitle: const Text('admin@thanecity.gov.in • Administrator'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'disable',
                        child: Text('Disable'),
                      ),
                    ],
                    onSelected: (value) => _handleUserAction(value),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.infoBlue,
                    child: Text('R', style: TextStyle(color: Colors.white)),
                  ),
                  title: const Text('Rajesh Kumar'),
                  subtitle: const Text('rajesh@thanecity.gov.in • Field Surveyor'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'disable',
                        child: Text('Disable'),
                      ),
                    ],
                    onSelected: (value) => _handleUserAction(value),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.secondaryGreen,
                    child: Text('P', style: TextStyle(color: Colors.white)),
                  ),
                  title: const Text('Priya Sharma'),
                  subtitle: const Text('priya@thanecity.gov.in • Field Surveyor'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'disable',
                        child: Text('Disable'),
                      ),
                    ],
                    onSelected: (value) => _handleUserAction(value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(bool isWide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports & Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Report Types
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildReportCard(
                'Tree Census Report',
                'Complete tree inventory with statistics',
                Icons.park,
                () => _generateReport('tree_census'),
              ),
              _buildReportCard(
                'Request Analysis',
                'Request trends and processing metrics',
                Icons.analytics,
                () => _generateReport('request_analysis'),
              ),
              _buildReportCard(
                'Ward-wise Summary',
                'Tree distribution across wards',
                Icons.location_city,
                () => _generateReport('ward_summary'),
              ),
              _buildReportCard(
                'Health Assessment',
                'Tree health status and recommendations',
                Icons.health_and_safety,
                () => _generateReport('health_assessment'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Reports
          Text(
            'Recent Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: AppTheme.errorRed),
                  title: const Text('Monthly Tree Census Report'),
                  subtitle: const Text('Generated on 15/01/2025'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadReport('monthly_census.pdf'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_chart, color: AppTheme.successGreen),
                  title: const Text('Request Processing Report'),
                  subtitle: const Text('Generated on 10/01/2025'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadReport('request_processing.xlsx'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryGreen),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  IconData _getUrgentItemIcon(String iconName) {
    switch (iconName) {
      case 'pending_actions':
        return Icons.pending_actions;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'account_balance':
        return Icons.account_balance;
      case 'assignment_late':
        return Icons.assignment_late;
      default:
        return Icons.warning;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action handlers
  void _handleUrgentAction(Map<String, dynamic> item) {
    switch (item['type']) {
      case 'requests':
        _tabController.animateTo(1); // Navigate to requests tab
        break;
      case 'trees':
        // Navigate to tree health management
        break;
      case 'heritage':
        // Navigate to heritage tree management
        break;
      case 'surveys':
        // Navigate to survey management
        break;
    }
  }

  void _navigateToRequests() {
    _tabController.animateTo(1);
  }

  void _manageUsers() {
    _tabController.animateTo(2);
  }

  void _generateReports() {
    _tabController.animateTo(3);
  }

  void _showSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _approveRequest(request) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request approval feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectRequest(request) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request rejection feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewRequestDetails(request) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request details feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addNewUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add user feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleUserAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User $action feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _generateReport(String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $reportType report...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadReport(String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $fileName...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showProfileInfo() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;
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
                CircleAvatar(
                  radius: 28,
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(user.email, style: const TextStyle(fontSize: 14)),
                      Text(user.role.displayName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
