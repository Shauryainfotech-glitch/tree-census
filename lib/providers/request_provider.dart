import 'package:flutter/foundation.dart';
import '../models/tree_request.dart';
import '../models/user.dart';
import '../services/request_service.dart';

class RequestProvider extends ChangeNotifier {
  List<TreeRequest> _requests = [];
  List<TreeRequest> _filteredRequests = [];
  TreeRequest? _selectedRequest;
  bool _isLoading = false;
  String? _errorMessage;
  RequestStatus? _statusFilter;
  RequestType? _typeFilter;
  String _searchQuery = '';

  // Getters
  List<TreeRequest> get requests => _filteredRequests;
  List<TreeRequest> get allRequests => _requests;
  TreeRequest? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RequestStatus? get statusFilter => _statusFilter;
  RequestType? get typeFilter => _typeFilter;
  String get searchQuery => _searchQuery;

  final RequestService _requestService = RequestService();

  // Load requests
  Future<void> loadRequests({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final requests = await _requestService.getRequests(forceRefresh: forceRefresh);
      _requests = requests;
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load requests: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Load user requests
  Future<void> loadUserRequests(String userId, {bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final requests = await _requestService.getUserRequests(userId, forceRefresh: forceRefresh);
      _requests = requests;
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load user requests: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Search requests
  void searchRequests(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  // Filter by status
  void filterByStatus(RequestStatus? status) {
    _statusFilter = status;
    _applyFilters();
  }

  // Filter by type
  void filterByType(RequestType? type) {
    _typeFilter = type;
    _applyFilters();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _typeFilter = null;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredRequests = _requests.where((request) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = request.applicantName.toLowerCase().contains(_searchQuery) ||
            request.id.toLowerCase().contains(_searchQuery) ||
            request.reason.toLowerCase().contains(_searchQuery) ||
            (request.treeId?.toLowerCase().contains(_searchQuery) ?? false);
        if (!matchesSearch) return false;
      }

      // Status filter
      if (_statusFilter != null && request.status != _statusFilter) {
        return false;
      }

      // Type filter
      if (_typeFilter != null && request.requestType != _typeFilter) {
        return false;
      }

      return true;
    }).toList();

    // Sort by submission date (newest first)
    _filteredRequests.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));

    notifyListeners();
  }

  // Get request by ID
  Future<TreeRequest?> getRequestById(String id) async {
    try {
      // First check in loaded requests
      final existingRequest = _requests.firstWhere(
        (request) => request.id == id,
        orElse: () => throw Exception('Request not found'),
      );
      return existingRequest;
    } catch (e) {
      // If not found locally, fetch from API
      try {
        final request = await _requestService.getRequestById(id);
        return request;
      } catch (e) {
        _setError('Failed to load request details: ${e.toString()}');
        return null;
      }
    }
  }

  // Select a request
  void selectRequest(TreeRequest request) {
    _selectedRequest = request;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedRequest = null;
    notifyListeners();
  }

  // Submit new request
  Future<bool> submitRequest(TreeRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final submittedRequest = await _requestService.submitRequest(request);
      _requests.add(submittedRequest);
      _applyFilters();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to submit request: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Update request
  Future<bool> updateRequest(TreeRequest request) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRequest = await _requestService.updateRequest(request);
      final index = _requests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _requests[index] = updatedRequest;
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update request: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Approve request (admin only)
  Future<bool> approveRequest(String requestId, String adminComments) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRequest = await _requestService.approveRequest(requestId, adminComments);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = updatedRequest;
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to approve request: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Reject request (admin only)
  Future<bool> rejectRequest(String requestId, String adminComments) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRequest = await _requestService.rejectRequest(requestId, adminComments);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = updatedRequest;
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to reject request: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Cancel request
  Future<bool> cancelRequest(String requestId) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRequest = await _requestService.cancelRequest(requestId);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = updatedRequest;
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to cancel request: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Mark request as in progress
  Future<bool> markInProgress(String requestId) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRequest = await _requestService.markInProgress(requestId);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = updatedRequest;
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to mark request as in progress: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Mark request as completed
  Future<bool> markCompleted(String requestId) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedRequest = await _requestService.markCompleted(requestId);
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _requests[index] = updatedRequest;
        _applyFilters();
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to mark request as completed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Get request statistics
  Map<String, dynamic> getRequestStatistics() {
    final totalRequests = _requests.length;
    final pendingRequests = _requests.where((r) => r.status == RequestStatus.pending).length;
    final approvedRequests = _requests.where((r) => r.status == RequestStatus.approved).length;
    final rejectedRequests = _requests.where((r) => r.status == RequestStatus.rejected).length;
    final inProgressRequests = _requests.where((r) => r.status == RequestStatus.inProgress).length;
    final completedRequests = _requests.where((r) => r.status == RequestStatus.completed).length;

    final typeCount = <RequestType, int>{};
    for (final request in _requests) {
      typeCount[request.requestType] = (typeCount[request.requestType] ?? 0) + 1;
    }

    return {
      'totalRequests': totalRequests,
      'pendingRequests': pendingRequests,
      'approvedRequests': approvedRequests,
      'rejectedRequests': rejectedRequests,
      'inProgressRequests': inProgressRequests,
      'completedRequests': completedRequests,
      'typeCount': typeCount,
      'approvalRate': totalRequests > 0 ? (approvedRequests / totalRequests * 100).round() : 0,
    };
  }

  // Get requests by status
  List<TreeRequest> getRequestsByStatus(RequestStatus status) {
    return _requests.where((request) => request.status == status).toList();
  }

  // Get requests by type
  List<TreeRequest> getRequestsByType(RequestType type) {
    return _requests.where((request) => request.requestType == type).toList();
  }

  // Get recent requests
  List<TreeRequest> getRecentRequests({int limit = 10}) {
    final sortedRequests = List<TreeRequest>.from(_requests);
    sortedRequests.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));
    return sortedRequests.take(limit).toList();
  }

  // Get urgent requests (pending for more than 7 days)
  List<TreeRequest> getUrgentRequests() {
    final urgentDate = DateTime.now().subtract(const Duration(days: 7));
    return _requests.where((request) => 
      request.status == RequestStatus.pending && 
      request.submissionDate.isBefore(urgentDate)
    ).toList();
  }

  // Calculate estimated fee
  double calculateEstimatedFee(RequestType type, {Map<String, dynamic>? additionalParams}) {
    double baseFee = type.baseFee;
    
    // Add any additional calculations based on tree size, location, etc.
    if (additionalParams != null) {
      final treeHeight = additionalParams['height'] as double?;
      final treeGirth = additionalParams['girth'] as double?;
      
      if (treeHeight != null && treeHeight > 20) {
        baseFee *= 1.5; // 50% surcharge for tall trees
      }
      
      if (treeGirth != null && treeGirth > 150) {
        baseFee *= 1.3; // 30% surcharge for large trees
      }
    }
    
    return baseFee;
  }

  // Export requests data
  Future<String> exportRequestsData({
    String format = 'csv',
    List<String>? fields,
  }) async {
    try {
      return await _requestService.exportRequests(
        requests: _filteredRequests,
        format: format,
        fields: fields,
      );
    } catch (e) {
      _setError('Failed to export data: ${e.toString()}');
      return '';
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load demo data for testing
  void loadDemoData() {
    _requests = [
      TreeRequest(
        id: 'REQ001',
        applicantName: 'John Doe',
        mobile: '+91 9876543210',
        aadhar: '1234 5678 9012',
        requestType: RequestType.pruning,
        treeId: 'TMC001',
        reason: 'Tree branches are interfering with power lines',
        status: RequestStatus.pending,
        submissionDate: DateTime.now().subtract(const Duration(days: 2)),
        applicantEmail: 'john.doe@email.com',
        address: '123 Main Street, Thane',
        fee: 500.0,
        paymentStatus: PaymentStatus.pending,
      ),
      TreeRequest(
        id: 'REQ002',
        applicantName: 'Jane Smith',
        mobile: '+91 9876543211',
        aadhar: '2345 6789 0123',
        requestType: RequestType.cutting,
        reason: 'Tree is diseased and poses safety risk',
        status: RequestStatus.approved,
        submissionDate: DateTime.now().subtract(const Duration(days: 5)),
        approvalDate: DateTime.now().subtract(const Duration(days: 1)),
        approvedBy: 'Admin User',
        adminComments: 'Approved after site inspection. Tree removal scheduled.',
        applicantEmail: 'jane.smith@email.com',
        address: '456 Oak Avenue, Thane',
        fee: 2000.0,
        paymentStatus: PaymentStatus.paid,
      ),
      TreeRequest(
        id: 'REQ003',
        applicantName: 'Bob Johnson',
        mobile: '+91 9876543212',
        aadhar: '3456 7890 1234',
        requestType: RequestType.treatment,
        treeId: 'TMC003',
        reason: 'Tree shows signs of pest infestation',
        status: RequestStatus.inProgress,
        submissionDate: DateTime.now().subtract(const Duration(days: 10)),
        approvalDate: DateTime.now().subtract(const Duration(days: 3)),
        approvedBy: 'Admin User',
        adminComments: 'Treatment approved. Pest control team assigned.',
        applicantEmail: 'bob.johnson@email.com',
        address: '789 Pine Road, Thane',
        fee: 1000.0,
        paymentStatus: PaymentStatus.paid,
      ),
    ];
    _applyFilters();
  }
}
