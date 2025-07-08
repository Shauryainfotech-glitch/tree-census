import 'package:flutter/foundation.dart';
import '../models/tree.dart';
import '../models/tree_request.dart';
import '../models/user.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  // Dashboard statistics
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _recentActivities = [];
  Map<String, List<double>> _chartData = {};
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // Getters
  Map<String, dynamic> get statistics => _statistics;
  List<Map<String, dynamic>> get recentActivities => _recentActivities;
  Map<String, List<double>> get chartData => _chartData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  final DashboardService _dashboardService = DashboardService();

  // Load dashboard data
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _dashboardService.getDashboardData(forceRefresh: forceRefresh);
      
      _statistics = data['statistics'] ?? {};
      _recentActivities = List<Map<String, dynamic>>.from(data['recentActivities'] ?? []);
      _chartData = Map<String, List<double>>.from(data['chartData'] ?? {});
      _lastUpdated = DateTime.now();
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load dashboard data: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Load statistics for specific user role
  Future<void> loadUserRoleStatistics(UserRole role) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await _dashboardService.getUserRoleStatistics(role);
      _statistics = data;
      _lastUpdated = DateTime.now();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load role statistics: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Get tree statistics
  Map<String, dynamic> getTreeStatistics() {
    return {
      'totalTrees': _statistics['totalTrees'] ?? 0,
      'heritageTrees': _statistics['heritageTrees'] ?? 0,
      'healthyTrees': _statistics['healthyTrees'] ?? 0,
      'diseasedTrees': _statistics['diseasedTrees'] ?? 0,
      'indigenousTrees': _statistics['indigenousTrees'] ?? 0,
      'nonIndigenousTrees': _statistics['nonIndigenousTrees'] ?? 0,
      'totalCanopy': _statistics['totalCanopy'] ?? 0.0,
      'averageAge': _statistics['averageAge'] ?? 0.0,
      'healthPercentage': _statistics['healthPercentage'] ?? 0,
    };
  }

  // Get request statistics
  Map<String, dynamic> getRequestStatistics() {
    return {
      'totalRequests': _statistics['totalRequests'] ?? 0,
      'pendingRequests': _statistics['pendingRequests'] ?? 0,
      'approvedRequests': _statistics['approvedRequests'] ?? 0,
      'rejectedRequests': _statistics['rejectedRequests'] ?? 0,
      'inProgressRequests': _statistics['inProgressRequests'] ?? 0,
      'completedRequests': _statistics['completedRequests'] ?? 0,
      'approvalRate': _statistics['approvalRate'] ?? 0,
      'averageProcessingTime': _statistics['averageProcessingTime'] ?? 0,
    };
  }

  // Get survey statistics
  Map<String, dynamic> getSurveyStatistics() {
    return {
      'totalSurveys': _statistics['totalSurveys'] ?? 0,
      'completedSurveys': _statistics['completedSurveys'] ?? 0,
      'activeSurveyors': _statistics['activeSurveyors'] ?? 0,
      'surveysThisMonth': _statistics['surveysThisMonth'] ?? 0,
      'averageSurveyTime': _statistics['averageSurveyTime'] ?? 0,
    };
  }

  // Get ward-wise statistics
  Map<String, dynamic> getWardStatistics() {
    return Map<String, dynamic>.from(_statistics['wardStatistics'] ?? {});
  }

  // Get species distribution
  Map<String, int> getSpeciesDistribution() {
    return Map<String, int>.from(_statistics['speciesDistribution'] ?? {});
  }

  // Get health distribution
  Map<String, int> getHealthDistribution() {
    return Map<String, int>.from(_statistics['healthDistribution'] ?? {});
  }

  // Get monthly trends
  List<double> getMonthlyTreeAdditions() {
    return List<double>.from(_chartData['monthlyTreeAdditions'] ?? []);
  }

  List<double> getMonthlyRequests() {
    return List<double>.from(_chartData['monthlyRequests'] ?? []);
  }

  List<double> getMonthlySurveys() {
    return List<double>.from(_chartData['monthlySurveys'] ?? []);
  }

  // Get top performing surveyors
  List<Map<String, dynamic>> getTopSurveyors() {
    return List<Map<String, dynamic>>.from(_statistics['topSurveyors'] ?? []);
  }

  // Get urgent items that need attention
  List<Map<String, dynamic>> getUrgentItems() {
    final urgentItems = <Map<String, dynamic>>[];
    
    // Add pending requests older than 7 days
    final oldPendingRequests = _statistics['oldPendingRequests'] ?? 0;
    if (oldPendingRequests > 0) {
      urgentItems.add({
        'type': 'requests',
        'title': 'Pending Requests',
        'description': '$oldPendingRequests requests pending for more than 7 days',
        'count': oldPendingRequests,
        'priority': 'high',
        'icon': 'pending_actions',
      });
    }

    // Add diseased trees
    final diseasedTrees = _statistics['diseasedTrees'] ?? 0;
    if (diseasedTrees > 0) {
      urgentItems.add({
        'type': 'trees',
        'title': 'Diseased Trees',
        'description': '$diseasedTrees trees require immediate attention',
        'count': diseasedTrees,
        'priority': 'high',
        'icon': 'local_hospital',
      });
    }

    // Add heritage trees needing inspection
    final heritageInspectionDue = _statistics['heritageInspectionDue'] ?? 0;
    if (heritageInspectionDue > 0) {
      urgentItems.add({
        'type': 'heritage',
        'title': 'Heritage Tree Inspection',
        'description': '$heritageInspectionDue heritage trees need inspection',
        'count': heritageInspectionDue,
        'priority': 'medium',
        'icon': 'account_balance',
      });
    }

    // Add incomplete surveys
    final incompleteSurveys = _statistics['incompleteSurveys'] ?? 0;
    if (incompleteSurveys > 0) {
      urgentItems.add({
        'type': 'surveys',
        'title': 'Incomplete Surveys',
        'description': '$incompleteSurveys surveys need completion',
        'count': incompleteSurveys,
        'priority': 'medium',
        'icon': 'assignment_late',
      });
    }

    return urgentItems;
  }

  // Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'surveyEfficiency': _statistics['surveyEfficiency'] ?? 0.0,
      'requestProcessingSpeed': _statistics['requestProcessingSpeed'] ?? 0.0,
      'dataAccuracy': _statistics['dataAccuracy'] ?? 0.0,
      'userSatisfaction': _statistics['userSatisfaction'] ?? 0.0,
      'systemUptime': _statistics['systemUptime'] ?? 0.0,
    };
  }

  // Get environmental impact metrics
  Map<String, dynamic> getEnvironmentalImpact() {
    return {
      'carbonSequestration': _statistics['carbonSequestration'] ?? 0.0,
      'oxygenProduction': _statistics['oxygenProduction'] ?? 0.0,
      'airPurification': _statistics['airPurification'] ?? 0.0,
      'biodiversityIndex': _statistics['biodiversityIndex'] ?? 0.0,
      'canopyCoverage': _statistics['canopyCoverage'] ?? 0.0,
    };
  }

  // Refresh specific data section
  Future<void> refreshTreeData() async {
    try {
      final data = await _dashboardService.getTreeStatistics();
      _statistics.addAll(data);
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh tree data: ${e.toString()}');
    }
  }

  Future<void> refreshRequestData() async {
    try {
      final data = await _dashboardService.getRequestStatistics();
      _statistics.addAll(data);
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh request data: ${e.toString()}');
    }
  }

  Future<void> refreshSurveyData() async {
    try {
      final data = await _dashboardService.getSurveyStatistics();
      _statistics.addAll(data);
      _lastUpdated = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh survey data: ${e.toString()}');
    }
  }

  // Export dashboard data
  Future<String> exportDashboardData({
    String format = 'pdf',
    List<String>? sections,
  }) async {
    try {
      return await _dashboardService.exportDashboardData(
        statistics: _statistics,
        chartData: _chartData,
        format: format,
        sections: sections,
      );
    } catch (e) {
      _setError('Failed to export dashboard data: ${e.toString()}');
      return '';
    }
  }

  // Generate reports
  Future<String> generateReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? wards,
    String format = 'pdf',
  }) async {
    try {
      return await _dashboardService.generateReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        wards: wards,
        format: format,
      );
    } catch (e) {
      _setError('Failed to generate report: ${e.toString()}');
      return '';
    }
  }

  // Get data freshness indicator
  String getDataFreshness() {
    if (_lastUpdated == null) return 'Never updated';
    
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Check if data needs refresh
  bool needsRefresh() {
    if (_lastUpdated == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);
    
    return difference.inMinutes > 30; // Refresh if data is older than 30 minutes
  }

  // Get summary for quick overview
  Map<String, dynamic> getQuickSummary() {
    return {
      'totalTrees': _statistics['totalTrees'] ?? 0,
      'pendingRequests': _statistics['pendingRequests'] ?? 0,
      'activeSurveyors': _statistics['activeSurveyors'] ?? 0,
      'healthyTreesPercentage': _statistics['healthPercentage'] ?? 0,
      'urgentItemsCount': getUrgentItems().length,
    };
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
    // Defer notifyListeners to after build phase to avoid setState() during build error
    _statistics = {
      'totalTrees': 1250,
      'heritageTrees': 45,
      'healthyTrees': 1100,
      'diseasedTrees': 80,
      'deadTrees': 20,
      'pendingRequests': 12,
      'completedRequests': 34,
      'activeSurveys': 5,
      'completedSurveys': 18,
    };
    _recentActivities = [
      {
        'type': 'tree_added',
        'title': 'New tree added',
        'description': 'Mango tree added in Ward 1 - Naupada',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'user': 'Rajesh Kumar',
      },
      {
        'type': 'request_approved',
        'title': 'Request approved',
        'description': 'Pruning request #REQ001 approved',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
        'user': 'Admin User',
      },
      {
        'type': 'survey_completed',
        'title': 'Survey completed',
        'description': '15 trees surveyed in Ward 2 - Kopri',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
        'user': 'Priya Sharma',
      },
    ];

    _lastUpdated = DateTime.now();
    notifyListeners();
  }
}
