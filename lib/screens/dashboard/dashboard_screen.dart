import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const DashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    dashboardProvider.loadDemoData(); // Load demo data for now
    // await dashboardProvider.loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trees'),
            Tab(text: 'Requests'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          if (dashboardProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (dashboardProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dashboardProvider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(dashboardProvider),
              _buildTreesTab(dashboardProvider),
              _buildRequestsTab(dashboardProvider),
              _buildAnalyticsTab(dashboardProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(DashboardProvider provider) {
    final quickSummary = provider.getQuickSummary();
    final urgentItems = provider.getUrgentItems();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data freshness indicator
            _buildDataFreshnessCard(provider),
            
            const SizedBox(height: 16),
            
            // Quick summary cards
            _buildQuickSummaryCards(quickSummary),
            
            const SizedBox(height: 24),
            
            // Urgent items
            if (urgentItems.isNotEmpty) ...[
              _buildSectionHeader('Urgent Items', Icons.priority_high),
              const SizedBox(height: 12),
              _buildUrgentItemsList(urgentItems),
              const SizedBox(height: 24),
            ],
            
            // Recent activities
            _buildSectionHeader('Recent Activities', Icons.history),
            const SizedBox(height: 12),
            _buildRecentActivitiesList(provider.recentActivities),
            
            const SizedBox(height: 24),
            
            // Performance metrics
            _buildSectionHeader('Performance Metrics', Icons.trending_up),
            const SizedBox(height: 12),
            _buildPerformanceMetrics(provider.getPerformanceMetrics()),
          ],
        ),
      ),
    );
  }

  Widget _buildTreesTab(DashboardProvider provider) {
    final treeStats = provider.getTreeStatistics();
    final speciesDistribution = provider.getSpeciesDistribution();
    final healthDistribution = provider.getHealthDistribution();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tree statistics cards
            _buildTreeStatisticsCards(treeStats),
            
            const SizedBox(height: 24),
            
            // Species distribution chart
            _buildSectionHeader('Species Distribution', Icons.pie_chart),
            const SizedBox(height: 12),
            _buildSpeciesDistributionChart(speciesDistribution),
            
            const SizedBox(height: 24),
            
            // Health distribution chart
            _buildSectionHeader('Health Distribution', Icons.favorite),
            const SizedBox(height: 12),
            _buildHealthDistributionChart(healthDistribution),
            
            const SizedBox(height: 24),
            
            // Environmental impact
            _buildSectionHeader('Environmental Impact', Icons.eco),
            const SizedBox(height: 12),
            _buildEnvironmentalImpact(provider.getEnvironmentalImpact()),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(DashboardProvider provider) {
    final requestStats = provider.getRequestStatistics();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request statistics cards
            _buildRequestStatisticsCards(requestStats),
            
            const SizedBox(height: 24),
            
            // Request trends chart
            _buildSectionHeader('Request Trends', Icons.show_chart),
            const SizedBox(height: 12),
            _buildRequestTrendsChart(provider.getMonthlyRequests()),
            
            const SizedBox(height: 24),
            
            // Processing metrics
            _buildSectionHeader('Processing Metrics', Icons.timer),
            const SizedBox(height: 12),
            _buildProcessingMetrics(requestStats),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(DashboardProvider provider) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly trends
            _buildSectionHeader('Monthly Trends', Icons.timeline),
            const SizedBox(height: 12),
            _buildMonthlyTrendsChart(provider),
            
            const SizedBox(height: 24),
            
            // Ward statistics
            _buildSectionHeader('Ward Statistics', Icons.location_city),
            const SizedBox(height: 12),
            _buildWardStatistics(provider.getWardStatistics()),
            
            const SizedBox(height: 24),
            
            // Top performers
            _buildSectionHeader('Top Surveyors', Icons.star),
            const SizedBox(height: 12),
            _buildTopSurveyors(provider.getTopSurveyors()),
          ],
        ),
      ),
    );
  }

  Widget _buildDataFreshnessCard(DashboardProvider provider) {
    final freshness = provider.getDataFreshness();
    final needsRefresh = provider.needsRefresh();

    return Card(
      color: needsRefresh ? AppTheme.warningOrange.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              needsRefresh ? Icons.warning : Icons.check_circle,
              color: needsRefresh ? AppTheme.warningOrange : AppTheme.successGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Last updated: $freshness',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (needsRefresh)
              TextButton(
                onPressed: _refreshData,
                child: const Text('Refresh'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummaryCards(Map<String, dynamic> summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1, // changed from 1.5 to 1.1 for more height
      children: [
        _buildSummaryCard(
          'Total Trees',
          summary['totalTrees'].toString(),
          Icons.park,
          AppTheme.primaryGreen,
        ),
        _buildSummaryCard(
          'Pending Requests',
          summary['pendingRequests'].toString(),
          Icons.pending_actions,
          AppTheme.warningOrange,
        ),
        _buildSummaryCard(
          'Active Surveyors',
          summary['activeSurveyors'].toString(),
          Icons.people,
          AppTheme.infoBlue,
        ),
        _buildSummaryCard(
          'Health Rate',
          '${summary['healthyTreesPercentage']}%',
          Icons.favorite,
          AppTheme.successGreen,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentItemsList(List<Map<String, dynamic>> urgentItems) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: urgentItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = urgentItems[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPriorityColor(item['priority']).withOpacity(0.2),
              child: Icon(
                _getIconData(item['icon']),
                color: _getPriorityColor(item['priority']),
              ),
            ),
            title: Text(item['title']),
            subtitle: Text(item['description']),
            trailing: Chip(
              label: Text(item['count'].toString()),
              backgroundColor: _getPriorityColor(item['priority']).withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivitiesList(List<Map<String, dynamic>> activities) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
              child: Icon(
                _getActivityIcon(activity['type']),
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            title: Text(activity['title']),
            subtitle: Text(activity['description']),
            trailing: Text(
              _formatTimestamp(activity['timestamp']),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTreeStatisticsCards(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1, // changed from 1.5 to 1.1 for more height
      children: [
        _buildSummaryCard(
          'Total Trees',
          stats['totalTrees'].toString(),
          Icons.park,
          AppTheme.primaryGreen,
        ),
        _buildSummaryCard(
          'Heritage Trees',
          stats['heritageTrees'].toString(),
          Icons.account_balance,
          AppColors.heritage,
        ),
        _buildSummaryCard(
          'Healthy Trees',
          stats['healthyTrees'].toString(),
          Icons.favorite,
          AppColors.treeHealthy,
        ),
        _buildSummaryCard(
          'Total Canopy',
          '${stats['totalCanopy']} m²',
          Icons.nature,
          AppTheme.secondaryGreen,
        ),
      ],
    );
  }

  Widget _buildRequestStatisticsCards(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1, // changed from 1.5 to 1.1 for more height
      children: [
        _buildSummaryCard(
          'Total Requests',
          stats['totalRequests'].toString(),
          Icons.request_page,
          AppTheme.primaryGreen,
        ),
        _buildSummaryCard(
          'Pending',
          stats['pendingRequests'].toString(),
          Icons.pending,
          AppColors.requestPending,
        ),
        _buildSummaryCard(
          'Approved',
          stats['approvedRequests'].toString(),
          Icons.check_circle,
          AppColors.requestApproved,
        ),
        _buildSummaryCard(
          'Approval Rate',
          '${stats['approvalRate']}%',
          Icons.trending_up,
          AppTheme.successGreen,
        ),
      ],
    );
  }

  Widget _buildSpeciesDistributionChart(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No species data available'),
          ),
        ),
      );
    }

    final sections = distribution.entries.take(5).map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: _getSpeciesColor(entry.key),
        radius: 60,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthDistributionChart(Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No health data available'),
          ),
        ),
      );
    }

    final sections = distribution.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: _getHealthColor(entry.key),
        radius: 60,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendsChart(DashboardProvider provider) {
    final treeData = provider.getMonthlyTreeAdditions();
    final requestData = provider.getMonthlyRequests();

    if (treeData.isEmpty && requestData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No trend data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                if (treeData.isNotEmpty)
                  LineChartBarData(
                    spots: treeData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.primaryGreen,
                    barWidth: 3,
                  ),
                if (requestData.isNotEmpty)
                  LineChartBarData(
                    spots: requestData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.warningOrange,
                    barWidth: 3,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(Map<String, dynamic> metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: metrics.entries.map((entry) {
            final value = entry.value as double;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatMetricName(entry.key),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: value / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPerformanceColor(value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${value.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnvironmentalImpact(Map<String, dynamic> impact) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: impact.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatMetricName(entry.key),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    _formatImpactValue(entry.key, entry.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWardStatistics(Map<String, dynamic> wardStats) {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: wardStats.length,
        itemBuilder: (context, index) {
          final entry = wardStats.entries.elementAt(index);
          final wardData = entry.value as Map<String, dynamic>;
          
          return ListTile(
            title: Text(entry.key),
            subtitle: Text('Trees: ${wardData['trees']}, Requests: ${wardData['requests']}'),
            trailing: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
              child: Text(
                wardData['trees'].toString(),
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSurveyors(List<Map<String, dynamic>> surveyors) {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: surveyors.length,
        itemBuilder: (context, index) {
          final surveyor = surveyors[index];
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(surveyor['name']),
            subtitle: Text('Surveys: ${surveyor['surveys']}'),
            trailing: Text(
              '${surveyor['accuracy']}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successGreen,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestTrendsChart(List<double> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No request trend data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value);
                  }).toList(),
                  isCurved: true,
                  color: AppTheme.warningOrange,
                  barWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingMetrics(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricRow('Average Processing Time', '${stats['averageProcessingTime']} days'),
            _buildMetricRow('Approval Rate', '${stats['approvalRate']}%'),
            _buildMetricRow('Completion Rate', '${stats['completionRate'] ?? 0}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return AppTheme.warningOrange;
      case 'low':
        return AppTheme.infoBlue;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getIconData(String iconName) {
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
        return Icons.info;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'tree_added':
        return Icons.add_circle;
      case 'request_approved':
        return Icons.check_circle;
      case 'survey_completed':
        return Icons.assignment_turned_in;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Color _getSpeciesColor(String species) {
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.secondaryGreen,
      AppTheme.accentGreen,
      AppColors.indigenous,
      AppColors.nonIndigenous,
    ];
    return colors[species.hashCode % colors.length];
  }

  Color _getHealthColor(String health) {
    switch (health.toLowerCase()) {
      case 'healthy':
        return AppColors.treeHealthy;
      case 'diseased':
        return AppColors.treeDiseased;
      case 'mechanically damaged':
        return AppColors.treeDamaged;
      case 'poor':
        return AppColors.treePoor;
      case 'uprooted':
        return AppColors.treeUprooted;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getPerformanceColor(double value) {
    if (value >= 90) {
      return AppTheme.successGreen;
    } else if (value >= 70) {
      return AppTheme.warningOrange;
    } else {
      return AppTheme.errorRed;
    }
  }

  String _formatMetricName(String key) {
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim().split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatImpactValue(String key, dynamic value) {
    switch (key) {
      case 'carbonSequestration':
        return '${value.toStringAsFixed(1)} tons CO₂';
      case 'oxygenProduction':
        return '${value.toStringAsFixed(1)} tons O₂';
      case 'airPurification':
        return '${value.toStringAsFixed(1)}%';
      case 'biodiversityIndex':
        return value.toStringAsFixed(2);
      case 'canopyCoverage':
        return '${value.toStringAsFixed(1)}%';
      default:
        return value.toString();
    }
  }

  Future<void> _refreshData() async {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    await dashboardProvider.loadDashboardData(forceRefresh: true);
  }

  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
