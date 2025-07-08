import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:tree_census/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/request_provider.dart';
import '../../utils/theme.dart';
import '../../models/tree_request.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Firestore users stream
  Stream<List<User>> get _usersStream => FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => User.fromJson(doc.data())).toList());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Removed _loadAdminData(); to avoid loading local/demo data
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        elevation: 4,
        backgroundColor: AppTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.primaryGreen.withValues(alpha: 0.7),
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
            _buildUsersTab(),
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
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 15, color: Colors.white70)),
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
              color: AppTheme.errorRed.withValues(alpha: 0.1),
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
                      backgroundColor: AppTheme.errorRed.withValues(alpha: 0.2),
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
                          backgroundColor: AppColors.requestPending.withValues(alpha: 0.2),
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

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
                onPressed: _showAddUserDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: _usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: Text(user.role.name),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String mobile = '';
    UserRole role = UserRole.citizen;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                  onChanged: (v) => name = v,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                  onChanged: (v) => email = v,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mobile'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter mobile' : null,
                  onChanged: (v) => mobile = v,
                  keyboardType: TextInputType.phone,
                ),
                DropdownButtonFormField<UserRole>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.values.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.name),
                  )).toList(),
                  onChanged: (r) => role = r!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final docRef = FirebaseFirestore.instance.collection('users').doc();
                await docRef.set({
                  'id': docRef.id,
                  'name': name,
                  'email': email,
                  'mobile': mobile,
                  'role': role.name,
                  'isActive': true,
                  'assignedWards': [],
                  'lastLogin': null,
                  'profileImage': null,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(bool isWide) {
    // Example recent reports data (replace with real data if available)
    final recentReports = [
      {
        'title': 'Monthly Tree Census Report',
        'subtitle': 'Generated on 15/01/2025',
        'icon': Icons.picture_as_pdf,
        'iconColor': AppTheme.errorRed,
        'file': 'monthly_census.pdf',
      },
      {
        'title': 'Request Processing Report',
        'subtitle': 'Generated on 10/01/2025',
        'icon': Icons.table_chart,
        'iconColor': AppTheme.successGreen,
        'file': 'request_processing.xlsx',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Report Types
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Report Types',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ListView(
              scrollDirection: Axis.horizontal,
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
          ),
          const SizedBox(height: 32),
          // Section: Recent Reports
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Reports',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() {}); // Replace with your refresh logic if needed
                  },
                ),
              ],
            ),
          ),
          if (recentReports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No recent reports found.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: recentReports.length,
                separatorBuilder: (context, i) => Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, i) {
                  final report = recentReports[i];
                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (report['iconColor'] as Color?)?.withOpacity(0.15) ?? Colors.grey[200],
                        child: Icon(
                          report['icon'] as IconData? ?? Icons.description,
                          color: report['iconColor'] as Color? ?? Theme.of(context).primaryColor,
                        ),
                      ),
                      title: Text(
                        report['title']?.toString() ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (report['subtitle'] != null)
                            Text(report['subtitle'] as String),
                          Text('Date:  \t${report['date']?.toString() ?? 'Unknown'}'),
                          Text('Status:  \t${report['status']?.toString() ?? 'N/A'}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download, size: 20, color: Colors.blueGrey),
                        tooltip: 'Download',
                        onPressed: () {
                          _downloadReport(report['file']?.toString() ?? '');
                        },
                      ),
                      onTap: () {
                        // TODO: Navigate to report details
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
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
}
