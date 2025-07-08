import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class DashboardService {
  final String _baseUrl = AppConstants.baseUrl;

  // Get comprehensive dashboard data
  Future<Map<String, dynamic>> getDashboardData({bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedData = await _getCachedDashboardData();
        if (cachedData != null) {
          return cachedData;
        }
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache the data
        await _cacheDashboardData(data);
        
        return data;
      } else {
        throw Exception('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      // Return cached data if available, otherwise throw error
      final cachedData = await _getCachedDashboardData();
      if (cachedData != null) {
        return cachedData;
      }
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  // Get statistics for specific user role
  Future<Map<String, dynamic>> getUserRoleStatistics(UserRole role) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}/role/${role.toString().split('.').last}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['statistics'] ?? {};
      } else {
        throw Exception('Failed to load role statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load role statistics: $e');
    }
  }

  // Get tree statistics
  Future<Map<String, dynamic>> getTreeStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.trees}/statistics'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['statistics'] ?? {};
      } else {
        throw Exception('Failed to load tree statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load tree statistics: $e');
    }
  }

  // Get request statistics
  Future<Map<String, dynamic>> getRequestStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.requests}/statistics'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['statistics'] ?? {};
      } else {
        throw Exception('Failed to load request statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load request statistics: $e');
    }
  }

  // Get survey statistics
  Future<Map<String, dynamic>> getSurveyStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.surveys}/statistics'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['statistics'] ?? {};
      } else {
        throw Exception('Failed to load survey statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load survey statistics: $e');
    }
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? wards,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (wards != null && wards.isNotEmpty) {
        queryParams['wards'] = wards.join(',');
      }

      final uri = Uri.parse('$_baseUrl${ApiEndpoints.analytics}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analytics'] ?? {};
      } else {
        throw Exception('Failed to load analytics data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load analytics data: $e');
    }
  }

  // Get ward-wise statistics
  Future<Map<String, dynamic>> getWardStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}/wards'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['wardStatistics'] ?? {};
      } else {
        throw Exception('Failed to load ward statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load ward statistics: $e');
    }
  }

  // Get species distribution
  Future<Map<String, int>> getSpeciesDistribution() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.trees}/species-distribution'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, int>.from(data['distribution'] ?? {});
      } else {
        throw Exception('Failed to load species distribution: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load species distribution: $e');
    }
  }

  // Get health distribution
  Future<Map<String, int>> getHealthDistribution() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.trees}/health-distribution'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, int>.from(data['distribution'] ?? {});
      } else {
        throw Exception('Failed to load health distribution: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load health distribution: $e');
    }
  }

  // Get monthly trends
  Future<Map<String, List<double>>> getMonthlyTrends() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.analytics}/monthly-trends'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final trends = <String, List<double>>{};
        
        for (final entry in data['trends'].entries) {
          trends[entry.key] = List<double>.from(entry.value);
        }
        
        return trends;
      } else {
        throw Exception('Failed to load monthly trends: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load monthly trends: $e');
    }
  }

  // Get recent activities
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}/activities?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['activities'] ?? []);
      } else {
        throw Exception('Failed to load recent activities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load recent activities: $e');
    }
  }

  // Get top performing surveyors
  Future<List<Map<String, dynamic>>> getTopSurveyors({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}/top-surveyors?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['surveyors'] ?? []);
      } else {
        throw Exception('Failed to load top surveyors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load top surveyors: $e');
    }
  }

  // Get urgent items
  Future<List<Map<String, dynamic>>> getUrgentItems() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}/urgent-items'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['urgentItems'] ?? []);
      } else {
        throw Exception('Failed to load urgent items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load urgent items: $e');
    }
  }

  // Get performance metrics
  Future<Map<String, double>> getPerformanceMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}/performance'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, double>.from(data['metrics'] ?? {});
      } else {
        throw Exception('Failed to load performance metrics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load performance metrics: $e');
    }
  }

  // Get environmental impact metrics
  Future<Map<String, double>> getEnvironmentalImpact() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}/environmental-impact'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, double>.from(data['impact'] ?? {});
      } else {
        throw Exception('Failed to load environmental impact: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load environmental impact: $e');
    }
  }

  // Generate report
  Future<String> generateReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? wards,
    String format = 'pdf',
  }) async {
    try {
      final requestBody = {
        'reportType': reportType,
        'format': format,
      };

      if (startDate != null) {
        requestBody['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        requestBody['endDate'] = endDate.toIso8601String();
      }
      if (wards != null && wards.isNotEmpty) {
        requestBody['wards'] = wards.join(',');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.reports}/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reportUrl'] ?? '';
      } else {
        throw Exception('Failed to generate report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  // Export dashboard data
  Future<String> exportDashboardData({
    required Map<String, dynamic> statistics,
    required Map<String, List<double>> chartData,
    String format = 'pdf',
    List<String>? sections,
  }) async {
    try {
      final requestBody = {
        'statistics': statistics,
        'chartData': chartData,
        'format': format,
        'sections': sections ?? ['all'],
      };

      final response = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.dashboard}/export'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exportUrl'] ?? '';
      } else {
        throw Exception('Failed to export dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to export dashboard data: $e');
    }
  }

  // Get system health
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['health'] ?? {};
      } else {
        throw Exception('Failed to get system health: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get system health: $e');
    }
  }

  // Cache dashboard data locally
  Future<void> _cacheDashboardData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dashboard_data', jsonEncode(data));
      await prefs.setString('dashboard_cache_time', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching dashboard data: $e');
    }
  }

  // Get cached dashboard data
  Future<Map<String, dynamic>?> _getCachedDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('dashboard_data');
      final cacheTime = prefs.getString('dashboard_cache_time');
      
      if (cachedData != null && cacheTime != null) {
        final cacheDateTime = DateTime.parse(cacheTime);
        final now = DateTime.now();
        
        // Check if cache is still valid (within cache expiry time)
        if (now.difference(cacheDateTime) < AppConstants.cacheExpiry) {
          return Map<String, dynamic>.from(jsonDecode(cachedData));
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting cached dashboard data: $e');
      return null;
    }
  }

  // Clear dashboard cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dashboard_data');
      await prefs.remove('dashboard_cache_time');
    } catch (e) {
      print('Error clearing dashboard cache: $e');
    }
  }

  // Get cache status
  Future<Map<String, dynamic>> getCacheStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getString('dashboard_cache_time');
      
      if (cacheTime != null) {
        final cacheDateTime = DateTime.parse(cacheTime);
        final now = DateTime.now();
        final age = now.difference(cacheDateTime);
        
        return {
          'hasCachedData': true,
          'cacheAge': age.inMinutes,
          'isExpired': age > AppConstants.cacheExpiry,
          'lastUpdated': cacheDateTime,
        };
      } else {
        return {
          'hasCachedData': false,
          'cacheAge': 0,
          'isExpired': true,
          'lastUpdated': null,
        };
      }
    } catch (e) {
      return {
        'hasCachedData': false,
        'cacheAge': 0,
        'isExpired': true,
        'lastUpdated': null,
      };
    }
  }

  // Calculate derived metrics
  Map<String, dynamic> calculateDerivedMetrics(Map<String, dynamic> rawData) {
    final derived = <String, dynamic>{};
    
    // Calculate percentages
    final totalTrees = rawData['totalTrees'] ?? 0;
    if (totalTrees > 0) {
      derived['healthyPercentage'] = ((rawData['healthyTrees'] ?? 0) / totalTrees * 100).round();
      derived['heritagePercentage'] = ((rawData['heritageTrees'] ?? 0) / totalTrees * 100).round();
      derived['indigenousPercentage'] = ((rawData['indigenousTrees'] ?? 0) / totalTrees * 100).round();
    }
    
    // Calculate request metrics
    final totalRequests = rawData['totalRequests'] ?? 0;
    if (totalRequests > 0) {
      derived['approvalRate'] = ((rawData['approvedRequests'] ?? 0) / totalRequests * 100).round();
      derived['completionRate'] = ((rawData['completedRequests'] ?? 0) / totalRequests * 100).round();
    }
    
    // Calculate survey efficiency
    final totalSurveys = rawData['totalSurveys'] ?? 0;
    final completedSurveys = rawData['completedSurveys'] ?? 0;
    if (totalSurveys > 0) {
      derived['surveyCompletionRate'] = (completedSurveys / totalSurveys * 100).round();
    }
    
    // Calculate trees per surveyor
    final activeSurveyors = rawData['activeSurveyors'] ?? 1;
    derived['treesPerSurveyor'] = (totalTrees / activeSurveyors).round();
    
    // Calculate average canopy per tree
    final totalCanopy = rawData['totalCanopy'] ?? 0.0;
    if (totalTrees > 0) {
      derived['averageCanopy'] = (totalCanopy / totalTrees);
    }
    
    return derived;
  }

  // Format numbers for display
  String formatNumber(dynamic number) {
    if (number == null) return '0';
    
    if (number is int) {
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}M';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(1)}K';
      } else {
        return number.toString();
      }
    } else if (number is double) {
      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}M';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(1)}K';
      } else {
        return number.toStringAsFixed(1);
      }
    }
    
    return number.toString();
  }

  // Get data freshness indicator
  String getDataFreshness(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'Never updated';
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
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
}
