import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tree_request.dart';
import '../../models/user.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    requestProvider.loadDemoData(); // Load demo data for now
    
    // In real app, load based on user role
    // if (authProvider.currentUser?.role == UserRole.citizen) {
    //   await requestProvider.loadUserRequests(authProvider.currentUser!.id);
    // } else {
    //   await requestProvider.loadRequests();
    // }
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
        title: const Text('Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          overlayColor: WidgetStateProperty.all(Colors.transparent), // Remove blue hover
          indicator: BoxDecoration(
            // borderRadius: BorderRadius.circular(30),
            // color: AppTheme.accentBlue.withAlpha(178), // 0.7 * 255 ≈ 178
          ),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search requests by ID, name, or type...',
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

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllRequestsTab(),
                _buildMyRequestsTab(),
                _buildPendingRequestsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRequest,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAllRequestsTab() {
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, child) {
        return _buildRequestsList(requestProvider.requests);
      },
    );
  }

  Widget _buildMyRequestsTab() {
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, child) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userRequests = requestProvider.requests.where((request) =>
            request.applicantName == authProvider.currentUser?.name).toList();
        return _buildRequestsList(userRequests);
      },
    );
  }

  Widget _buildPendingRequestsTab() {
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, child) {
        final pendingRequests = requestProvider.getRequestsByStatus(RequestStatus.pending);
        return _buildRequestsList(pendingRequests);
      },
    );
  }

  Widget _buildRequestsList(List<TreeRequest> requests) {
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, child) {
        if (requestProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (requestProvider.errorMessage != null) {
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
                  'Error loading requests',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  requestProvider.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadRequests,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No requests found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Submit your first request to get started',
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createNewRequest,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Request'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadRequests,
          child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(context, request);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, TreeRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showRequestDetails(context, request),
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
                          request.requestType.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${request.id}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(request.status.displayName),
                        backgroundColor: _getStatusColor(request.status).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: _getStatusColor(request.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (request.fee != null)
                        Text(
                          '₹${request.fee!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Applicant Info
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request.applicantName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    request.mobile,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Tree ID (if available)
              if (request.treeId != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.park,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tree ID: ${request.treeId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Reason (truncated)
              Text(
                request.reason,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Footer Row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(request.submissionDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (request.paymentStatus != null) ...[
                    Icon(
                      _getPaymentIcon(request.paymentStatus!),
                      size: 16,
                      color: _getPaymentColor(request.paymentStatus!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.paymentStatus!.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getPaymentColor(request.paymentStatus!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(BuildContext context, TreeRequest request) {
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
          return _buildRequestDetailsSheet(context, request, scrollController);
        },
      ),
    );
  }

  Widget _buildRequestDetailsSheet(BuildContext context, TreeRequest request, ScrollController scrollController) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.currentUser?.role == UserRole.admin;
    
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
          
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requestType.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Request ID: ${request.id}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(request.status.displayName),
                backgroundColor: _getStatusColor(request.status).withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _getStatusColor(request.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Applicant Information
          _buildDetailSection(
            'Applicant Information',
            [
              _buildDetailRow('Name', request.applicantName),
              _buildDetailRow('Mobile', request.mobile),
              _buildDetailRow('Email', request.applicantEmail),
              _buildDetailRow('Address', request.address),
              _buildDetailRow('Aadhar', request.aadhar),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Request Details
          _buildDetailSection(
            'Request Details',
            [
              _buildDetailRow('Type', request.requestType.displayName),
              if (request.treeId != null)
                _buildDetailRow('Tree ID', request.treeId!),
              _buildDetailRow('Submission Date', _formatDate(request.submissionDate)),
              _buildDetailRow('Reason', request.reason, isMultiline: true),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Fee Information
          if (request.fee != null) ...[
            _buildDetailSection(
              'Fee Information',
              [
                _buildDetailRow('Amount', '₹${request.fee!.toStringAsFixed(0)}'),
                if (request.paymentStatus != null)
                  _buildDetailRow('Payment Status', request.paymentStatus!.displayName),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Admin Information (if available)
          if (request.adminComments != null || request.approvedBy != null) ...[
            _buildDetailSection(
              'Administrative Information',
              [
                if (request.approvedBy != null)
                  _buildDetailRow('Processed By', request.approvedBy!),
                if (request.approvalDate != null)
                  _buildDetailRow('Processing Date', _formatDate(request.approvalDate!)),
                if (request.adminComments != null)
                  _buildDetailRow('Comments', request.adminComments!, isMultiline: true),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Action Buttons
          if (isAdmin && request.status == RequestStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectRequest(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveRequest(request),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ] else if (request.status == RequestStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelRequest(request),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                ),
                child: const Text('Cancel Request'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: isMultiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '$label:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return AppColors.requestPending;
      case RequestStatus.approved:
        return AppColors.requestApproved;
      case RequestStatus.rejected:
        return AppColors.requestRejected;
      case RequestStatus.inProgress:
        return AppColors.requestInProgress;
      case RequestStatus.completed:
        return AppColors.requestCompleted;
      case RequestStatus.cancelled:
        return AppTheme.textSecondary;
    }
  }

  IconData _getPaymentIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.undo;
    }
  }

  Color _getPaymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return AppTheme.warningOrange;
      case PaymentStatus.paid:
        return AppTheme.successGreen;
      case PaymentStatus.failed:
        return AppTheme.errorRed;
      case PaymentStatus.refunded:
        return AppTheme.infoBlue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _performSearch(String query) {
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    requestProvider.searchRequests(query);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Requests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Filter
            DropdownButtonFormField<RequestStatus>(
              decoration: const InputDecoration(labelText: 'Status'),
              items: RequestStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (status) {
                // Apply status filter
              },
            ),
            const SizedBox(height: 16),
            // Type Filter
            DropdownButtonFormField<RequestType>(
              decoration: const InputDecoration(labelText: 'Type'),
              items: RequestType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (type) {
                // Apply type filter
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _createNewRequest() {
    context.push('/request-form');
  }

  void _approveRequest(TreeRequest request) {
    // TODO: Implement request approval
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request approval feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rejectRequest(TreeRequest request) {
    // TODO: Implement request rejection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request rejection feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelRequest(TreeRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement request cancellation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request cancellation feature coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
