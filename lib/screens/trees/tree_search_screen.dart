import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tree_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tree.dart';
import '../../models/user.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class TreeSearchScreen extends StatefulWidget {
  const TreeSearchScreen({super.key});

  @override
  State<TreeSearchScreen> createState() => _TreeSearchScreenState();
}

class _TreeSearchScreenState extends State<TreeSearchScreen> {
  final _searchController = TextEditingController();
  TreeHealth? _selectedHealth;
  String? _selectedWard;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrees() async {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    treeProvider.loadDemoData(); // Load demo data
    await treeProvider.getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Search Trees'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_off),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search trees by species, ID, or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _performSearch,
            ),
          ),

          // Filters
          if (_showFilters) _buildFilters(),

          // Results
          Expanded(
            child: Consumer<TreeProvider>(
              builder: (context, treeProvider, child) {
                if (treeProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (treeProvider.errorMessage != null) {
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
                          'Error loading trees',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          treeProvider.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTrees,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final trees = treeProvider.trees;

                if (trees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trees found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting your search criteria',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadTrees,
                  child: ListView.builder(
                    itemCount: trees.length,
                    itemBuilder: (context, index) {
                      final tree = trees[index];
                      return _buildTreeCard(tree, treeProvider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Health Filter
            DropdownButtonFormField<TreeHealth>(
              value: _selectedHealth,
              decoration: const InputDecoration(
                labelText: 'Health Status',
                prefixIcon: Icon(Icons.favorite),
              ),
              items: TreeHealth.values.map((health) {
                return DropdownMenuItem(
                  value: health,
                  child: Text(health.displayName),
                );
              }).toList(),
              onChanged: (health) {
                setState(() {
                  _selectedHealth = health;
                });
                _applyFilters();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Ward Filter
            DropdownButtonFormField<String>(
              value: _selectedWard,
              decoration: const InputDecoration(
                labelText: 'Ward',
                prefixIcon: Icon(Icons.location_city),
              ),
              items: AppConstants.thaneWards.map((ward) {
                return DropdownMenuItem(
                  value: ward,
                  child: Text(ward),
                );
              }).toList(),
              onChanged: (ward) {
                setState(() {
                  _selectedWard = ward;
                });
                _applyFilters();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeCard(Tree tree, TreeProvider treeProvider) {
    final distance = treeProvider.getDistanceToTree(tree);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showTreeDetails(tree),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tree.localName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tree.species,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(tree.health.displayName),
                        backgroundColor: _getHealthColor(tree.health).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: _getHealthColor(tree.health),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (tree.heritage)
                        const Chip(
                          label: Text('Heritage'),
                          backgroundColor: AppColors.heritage,
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tree Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.height,
                      'Height',
                      '${tree.height.toStringAsFixed(1)}m',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.straighten,
                      'Girth',
                      '${tree.girth.toStringAsFixed(1)}cm',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.calendar_today,
                      'Age',
                      '${tree.age} years',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Location Info
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tree.ward,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (distance != null) ...[
                    Icon(
                      Icons.near_me,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(distance),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Tree ID
              const SizedBox(height: 8),
              Text(
                'ID: ${tree.id}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryGreen,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _performSearch(String query) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    treeProvider.searchTrees(query);
  }

  void _applyFilters() {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    treeProvider.filterByHealth(_selectedHealth);
    treeProvider.filterByWard(_selectedWard);
  }

  void _clearFilters() {
    setState(() {
      _selectedHealth = null;
      _selectedWard = null;
    });
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    treeProvider.clearFilters();
  }

  Future<void> _getCurrentLocation() async {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    await treeProvider.getCurrentLocation();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated. Trees sorted by distance.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTreeDetails(Tree tree) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return _buildTreeDetailsSheet(tree, scrollController);
        },
      ),
    );
  }

  Widget _buildTreeDetailsSheet(Tree tree, ScrollController scrollController) {
    final treeProvider = Provider.of<TreeProvider>(context, listen: false);
    final distance = treeProvider.getDistanceToTree(tree);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Tree Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tree.localName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tree.species,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (tree.heritage)
                const Icon(
                  Icons.account_balance,
                  color: AppColors.heritage,
                  size: 32,
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Tree Metrics
          _buildMetricsGrid(tree),
          
          const SizedBox(height: 24),
          
          // Location Information
          _buildLocationInfo(tree, distance),
          
          const SizedBox(height: 24),
          
          // Health Information
          _buildHealthInfo(tree),
          
          if (tree.notes != null && tree.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildNotesSection(tree),
          ],
          
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(tree),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Tree tree) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tree Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard('Height', '${tree.height.toStringAsFixed(1)} m', Icons.height),
                _buildMetricCard('Girth', '${tree.girth.toStringAsFixed(1)} cm', Icons.straighten),
                _buildMetricCard('Age', '${tree.age} years', Icons.calendar_today),
                _buildMetricCard('Canopy', '${tree.canopy.toStringAsFixed(1)} m²', Icons.nature),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryGreen),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(Tree tree, double? distance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_city, 'Ward', tree.ward),
            _buildInfoRow(Icons.business, 'Ownership', tree.ownership.displayName),
            _buildInfoRow(Icons.gps_fixed, 'Coordinates', 
                '${tree.lat.toStringAsFixed(6)}, ${tree.lng.toStringAsFixed(6)}'),
            if (distance != null)
              _buildInfoRow(Icons.near_me, 'Distance', _formatDistance(distance)),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInfo(Tree tree) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: _getHealthColor(tree.health),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tree.health.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getHealthColor(tree.health),
                        ),
                      ),
                      Text(
                        tree.health.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (tree.lastSurveyDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.calendar_today, 'Last Survey', 
                  _formatDate(tree.lastSurveyDate!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(Tree tree) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tree.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Tree tree) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    return Column(
      children: [
        if (user?.role.permissions.contains('submit_requests') == true)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _submitRequest(tree),
              icon: const Icon(Icons.request_page),
              label: const Text('Submit Request'),
            ),
          ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOnMap(tree),
                icon: const Icon(Icons.map),
                label: const Text('View on Map'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareTree(tree),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getHealthColor(TreeHealth health) {
    switch (health) {
      case TreeHealth.healthy:
        return AppColors.treeHealthy;
      case TreeHealth.diseased:
        return AppColors.treeDiseased;
      case TreeHealth.mechanicallyDamaged:
        return AppColors.treeDamaged;
      case TreeHealth.poor:
        return AppColors.treePoor;
      case TreeHealth.uprooted:
        return AppColors.treeUprooted;
    }
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _submitRequest(Tree tree) {
    // TODO: Navigate to request form with tree pre-selected
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request submission feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOnMap(Tree tree) {
    // TODO: Navigate to map view with tree location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map view feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareTree(Tree tree) {
    // TODO: Implement tree sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
