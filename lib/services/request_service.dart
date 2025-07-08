import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/tree_request.dart';
import '../utils/constants.dart';

class RequestService {
  final String _baseUrl = AppConstants.baseUrl;
  late Box<TreeRequest> _requestBox;

  RequestService() {
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      _requestBox = await Hive.openBox<TreeRequest>(AppConstants.requestsBox);
    } catch (e) {
      print('Error initializing Hive: $e');
    }
  }

  // Get all requests
  Future<List<TreeRequest>> getRequests({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _requestBox.isNotEmpty) {
        return _requestBox.values.toList();
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.requests}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> requestsJson = data['requests'] ?? [];
        
        final requests = requestsJson.map((json) => TreeRequest.fromJson(json)).toList();
        await _cacheRequestsLocally(requests);
        return requests;
      } else {
        throw Exception('Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      if (_requestBox.isNotEmpty) {
        return _requestBox.values.toList();
      }
      throw Exception('Failed to load requests: $e');
    }
  }

  // Get user requests
  Future<List<TreeRequest>> getUserRequests(String userId, {bool forceRefresh = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.requestsByUser.replaceAll('{userId}', userId)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> requestsJson = data['requests'] ?? [];
        return requestsJson.map((json) => TreeRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user requests: $e');
    }
  }

  // Get request by ID
  Future<TreeRequest> getRequestById(String id) async {
    try {
      final cachedRequest = _requestBox.get(id);
      if (cachedRequest != null) {
        return cachedRequest;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.requestById.replaceAll('{id}', id)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final request = TreeRequest.fromJson(data['request']);
        await _requestBox.put(request.id, request);
        return request;
      } else {
        throw Exception('Request not found');
      }
    } catch (e) {
      throw Exception('Failed to load request: $e');
    }
  }

  // Submit new request
  Future<TreeRequest> submitRequest(TreeRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.requests}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newRequest = TreeRequest.fromJson(data['request']);
        await _requestBox.put(newRequest.id, newRequest);
        return newRequest;
      } else {
        throw Exception('Failed to submit request: ${response.statusCode}');
      }
    } catch (e) {
      await _storeOfflineAction('submit', request);
      throw Exception('Failed to submit request: $e');
    }
  }

  // Update request
  Future<TreeRequest> updateRequest(TreeRequest request) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl${ApiEndpoints.requestById.replaceAll('{id}', request.id)}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedRequest = TreeRequest.fromJson(data['request']);
        await _requestBox.put(updatedRequest.id, updatedRequest);
        return updatedRequest;
      } else {
        throw Exception('Failed to update request: ${response.statusCode}');
      }
    } catch (e) {
      await _storeOfflineAction('update', request);
      throw Exception('Failed to update request: $e');
    }
  }

  // Approve request (admin only)
  Future<TreeRequest> approveRequest(String requestId, String adminComments) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.requestApproval.replaceAll('{id}', requestId)}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'adminComments': adminComments}),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedRequest = TreeRequest.fromJson(data['request']);
        await _requestBox.put(updatedRequest.id, updatedRequest);
        return updatedRequest;
      } else {
        throw Exception('Failed to approve request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  // Reject request (admin only)
  Future<TreeRequest> rejectRequest(String requestId, String adminComments) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiEndpoints.requestRejection.replaceAll('{id}', requestId)}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'adminComments': adminComments}),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedRequest = TreeRequest.fromJson(data['request']);
        await _requestBox.put(updatedRequest.id, updatedRequest);
        return updatedRequest;
      } else {
        throw Exception('Failed to reject request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  // Cancel request
  Future<TreeRequest> cancelRequest(String requestId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl${ApiEndpoints.requestById.replaceAll('{id}', requestId)}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'cancelled'}),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedRequest = TreeRequest.fromJson(data['request']);
        await _requestBox.put(updatedRequest.id, updatedRequest);
        return updatedRequest;
      } else {
        throw Exception('Failed to cancel request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to cancel request: $e');
    }
  }

  // Mark request as in progress
  Future<TreeRequest> markInProgress(String requestId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl${ApiEndpoints.requestById.replaceAll('{id}', requestId)}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'inProgress'}),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedRequest = TreeRequest.fromJson(data['request']);
        await _requestBox.put(updatedRequest.id, updatedRequest);
        return updatedRequest;
      } else {
        throw Exception('Failed to mark request as in progress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark request as in progress: $e');
    }
  }

  // Mark request as completed
  Future<TreeRequest> markCompleted(String requestId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl${ApiEndpoints.requestById.replaceAll('{id}', requestId)}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'completed'}),
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedRequest = TreeRequest.fromJson(data['request']);
        await _requestBox.put(updatedRequest.id, updatedRequest);
        return updatedRequest;
      } else {
        throw Exception('Failed to mark request as completed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark request as completed: $e');
    }
  }

  // Export requests data
  Future<String> exportRequests({
    required List<TreeRequest> requests,
    String format = 'csv',
    List<String>? fields,
  }) async {
    try {
      if (format.toLowerCase() == 'csv') {
        return _exportToCSV(requests, fields);
      } else if (format.toLowerCase() == 'json') {
        return _exportToJSON(requests, fields);
      } else {
        throw Exception('Unsupported export format: $format');
      }
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  // Private helper methods
  Future<void> _cacheRequestsLocally(List<TreeRequest> requests) async {
    try {
      await _requestBox.clear();
      for (final request in requests) {
        await _requestBox.put(request.id, request);
      }
    } catch (e) {
      print('Error caching requests: $e');
    }
  }

  Future<void> _storeOfflineAction(String type, TreeRequest request) async {
    try {
      final offlineBox = await Hive.openBox('offline_request_actions');
      final actionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await offlineBox.put(actionId, {
        'type': type,
        'request': request.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error storing offline action: $e');
    }
  }

  String _exportToCSV(List<TreeRequest> requests, List<String>? fields) {
    final selectedFields = fields ?? [
      'id', 'applicantName', 'mobile', 'requestType', 'status', 
      'submissionDate', 'reason', 'fee', 'paymentStatus'
    ];

    final csvLines = <String>[];
    csvLines.add(selectedFields.join(','));
    
    for (final request in requests) {
      final row = selectedFields.map((field) {
        switch (field) {
          case 'id':
            return request.id;
          case 'applicantName':
            return request.applicantName;
          case 'mobile':
            return request.mobile;
          case 'requestType':
            return request.requestType.displayName;
          case 'status':
            return request.status.displayName;
          case 'submissionDate':
            return request.submissionDate.toIso8601String();
          case 'reason':
            return request.reason;
          case 'fee':
            return request.fee?.toString() ?? '';
          case 'paymentStatus':
            return request.paymentStatus?.displayName ?? '';
          default:
            return '';
        }
      }).join(',');
      
      csvLines.add(row);
    }
    
    return csvLines.join('\n');
  }

  String _exportToJSON(List<TreeRequest> requests, List<String>? fields) {
    if (fields == null) {
      return jsonEncode(requests.map((request) => request.toJson()).toList());
    }

    final filteredRequests = requests.map((request) {
      final requestJson = request.toJson();
      final filteredJson = <String, dynamic>{};
      
      for (final field in fields) {
        if (requestJson.containsKey(field)) {
          filteredJson[field] = requestJson[field];
        }
      }
      
      return filteredJson;
    }).toList();

    return jsonEncode(filteredRequests);
  }
}
