import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tree.dart';
import '../utils/constants.dart';

class SurveyService {
  final String _baseUrl = AppConstants.baseUrl;
  final String _aiServiceUrl = AppConstants.aiServiceUrl;

  // Submit survey with tree data and images
  Future<Map<String, dynamic>> submitSurvey(Tree tree, List<File> images) async {
    try {
      // For demo purposes, simulate API submission since the server URLs are placeholders
      // In production, replace this with actual API calls

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Check if we're in demo mode (placeholder URLs)
      final isDemoMode = _baseUrl.contains('thanecity.gov.in') ||
          _baseUrl.contains('localhost') ||
          _baseUrl.contains('example.com');

      if (isDemoMode) {
        // Simulate successful submission for demo
        final surveyId = 'TMC${DateTime.now().millisecondsSinceEpoch}';

        return {
          'success': true,
          'tree': {
            ...tree.toJson(),
            'id': surveyId,
            'status': 'submitted',
            'submittedAt': DateTime.now().toIso8601String(),
          },
          'message': 'Survey submitted successfully (Demo Mode)',
          'surveyId': surveyId,
          'demo': true,
        };
      }

      // Original API submission code for production
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl${ApiEndpoints.surveySubmit}'),
      );

      // Add tree data as JSON field
      request.fields['treeData'] = jsonEncode(tree.toJson());

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final multipartFile = await http.MultipartFile.fromPath(
          'images',
          file.path,
          filename: 'tree_image_$i.jpg',
        );
        request.files.add(multipartFile);
      }

      // Send request
      final response = await request.send().timeout(AppConstants.uploadTimeout);
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'tree': data['tree'],
          'message': 'Survey submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Survey submission failed',
        };
      }
    } catch (e) {
      // Store offline for later sync
      await _storeOfflineSurvey(tree, images);
      return {
        'success': false,
        'message': 'Survey stored offline for later sync',
        'offline': true,
      };
    }
  }

  // AI-powered species identification
  Future<Map<String, dynamic>> identifySpecies(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_aiServiceUrl${ApiEndpoints.aiSpeciesIdentification}'),
      );

      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'tree_species.jpg',
      );
      request.files.add(multipartFile);

      final response = await request.send().timeout(AppConstants.apiTimeout);
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'species': data['species'],
          'localName': data['localName'],
          'confidence': data['confidence'],
          'alternatives': data['alternatives'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Species identification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'AI service unavailable. Please identify manually.',
      };
    }
  }

  // AI-powered health assessment
  Future<Map<String, dynamic>> assessHealth(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_aiServiceUrl${ApiEndpoints.aiHealthAssessment}'),
      );

      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'tree_health.jpg',
      );
      request.files.add(multipartFile);

      final response = await request.send().timeout(AppConstants.apiTimeout);
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'health': data['health'],
          'confidence': data['confidence'],
          'recommendations': data['recommendations'] ?? [],
          'diseases': data['diseases'] ?? [],
          'riskLevel': data['riskLevel'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Health assessment failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'AI service unavailable. Please assess manually.',
      };
    }
  }

  // AI risk analysis
  Future<Map<String, dynamic>> analyzeRisk(File imageFile, Map<String, dynamic> treeData) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_aiServiceUrl${ApiEndpoints.aiRiskAnalysis}'),
      );

      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'tree_risk.jpg',
      );
      request.files.add(multipartFile);

      // Add tree data for context
      request.fields['treeData'] = jsonEncode(treeData);

      final response = await request.send().timeout(AppConstants.apiTimeout);
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'riskLevel': data['riskLevel'],
          'riskFactors': data['riskFactors'] ?? [],
          'recommendations': data['recommendations'] ?? [],
          'urgency': data['urgency'],
          'confidence': data['confidence'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Risk analysis failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'AI service unavailable. Please assess manually.',
      };
    }
  }

  // Save survey draft
  Future<void> saveDraft(Map<String, dynamic> draftData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsBox = await Hive.openBox('survey_drafts');

      final draftId = draftData['surveyId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await draftsBox.put(draftId, draftData);

      // Keep track of draft IDs
      final draftIds = prefs.getStringList('survey_draft_ids') ?? [];
      if (!draftIds.contains(draftId)) {
        draftIds.add(draftId);
        await prefs.setStringList('survey_draft_ids', draftIds);
      }
    } catch (e) {
      throw Exception('Failed to save draft: $e');
    }
  }

  // Load survey draft
  Future<Map<String, dynamic>?> loadDraft(String draftId) async {
    try {
      final draftsBox = await Hive.openBox('survey_drafts');
      final draftData = draftsBox.get(draftId);

      if (draftData != null) {
        return Map<String, dynamic>.from(draftData);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to load draft: $e');
    }
  }

  // Get all survey drafts
  Future<List<Map<String, dynamic>>> getAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsBox = await Hive.openBox('survey_drafts');
      final draftIds = prefs.getStringList('survey_draft_ids') ?? [];

      final drafts = <Map<String, dynamic>>[];

      for (final draftId in draftIds) {
        final draftData = draftsBox.get(draftId);
        if (draftData != null) {
          final draft = Map<String, dynamic>.from(draftData);
          draft['id'] = draftId;
          drafts.add(draft);
        }
      }

      // Sort by timestamp (newest first)
      drafts.sort((a, b) {
        final timestampA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
        final timestampB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
        return timestampB.compareTo(timestampA);
      });

      return drafts;
    } catch (e) {
      throw Exception('Failed to get drafts: $e');
    }
  }

  // Delete survey draft
  Future<void> deleteDraft(String draftId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsBox = await Hive.openBox('survey_drafts');

      await draftsBox.delete(draftId);

      // Remove from draft IDs list
      final draftIds = prefs.getStringList('survey_draft_ids') ?? [];
      draftIds.remove(draftId);
      await prefs.setStringList('survey_draft_ids', draftIds);
    } catch (e) {
      throw Exception('Failed to delete draft: $e');
    }
  }

  // Get survey statistics
  Future<Map<String, dynamic>> getSurveyStatistics(String surveyorId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiEndpoints.surveysByUser.replaceAll('{userId}', surveyorId)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['statistics'] ?? {};
      } else {
        throw Exception('Failed to get survey statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get survey statistics: $e');
    }
  }

  // Validate survey data
  Map<String, String> validateSurveyData(Map<String, dynamic> surveyData) {
    final errors = <String, String>{};

    // Required fields validation
    if (surveyData['scientificName'] == null || surveyData['scientificName'].toString().isEmpty) {
      errors['scientificName'] = 'Scientific name is required';
    }

    if (surveyData['localName'] == null || surveyData['localName'].toString().isEmpty) {
      errors['localName'] = 'Local name is required';
    }

    if (surveyData['height'] == null || surveyData['height'] <= 0) {
      errors['height'] = 'Valid height is required';
    } else if (surveyData['height'] < AppConstants.minTreeHeight) {
      errors['height'] = 'Height must be at least ${AppConstants.minTreeHeight}m for census criteria';
    }

    if (surveyData['girth'] == null || surveyData['girth'] <= 0) {
      errors['girth'] = 'Valid girth is required';
    } else if (surveyData['girth'] < AppConstants.minTreeGirth) {
      errors['girth'] = 'Girth must be at least ${AppConstants.minTreeGirth}cm for census criteria';
    }

    if (surveyData['age'] == null || surveyData['age'] <= 0) {
      errors['age'] = 'Valid age is required';
    }

    if (surveyData['healthCondition'] == null) {
      errors['healthCondition'] = 'Health condition is required';
    }

    if (surveyData['ownership'] == null) {
      errors['ownership'] = 'Ownership type is required';
    }

    if (surveyData['canopy'] == null || surveyData['canopy'] <= 0) {
      errors['canopy'] = 'Valid canopy spread is required';
    }

    if (surveyData['ward'] == null || surveyData['ward'].toString().isEmpty) {
      errors['ward'] = 'Ward information is required';
    }

    if (surveyData['location'] == null) {
      errors['location'] = 'GPS location is required';
    }

    // Heritage tree validation
    if (surveyData['age'] != null && surveyData['age'] >= AppConstants.heritageTreeAge) {
      if (surveyData['isHeritage'] != true) {
        errors['heritage'] = 'Trees aged ${AppConstants.heritageTreeAge}+ years should be marked as heritage';
      }
    }

    return errors;
  }

  // Get species suggestions based on input
  Future<List<String>> getSpeciesSuggestions(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/species/suggestions?q=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['suggestions'] ?? []);
      } else {
        // Return local suggestions if API fails
        return _getLocalSpeciesSuggestions(query);
      }
    } catch (e) {
      // Return local suggestions if network fails
      return _getLocalSpeciesSuggestions(query);
    }
  }

  // Get local species suggestions
  List<String> _getLocalSpeciesSuggestions(String query) {
    final lowercaseQuery = query.toLowerCase();
    return AppConstants.commonTreeSpecies
        .where((species) => species.toLowerCase().contains(lowercaseQuery))
        .take(10)
        .toList();
  }

  // Store offline survey for later sync
  Future<void> _storeOfflineSurvey(Tree tree, List<File> images) async {
    try {
      final offlineBox = await Hive.openBox('offline_surveys');
      final surveyId = DateTime.now().millisecondsSinceEpoch.toString();

      // Copy images to permanent storage
      final imagePaths = <String>[];
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final permanentPath = await _copyImageToPermanentStorage(image, surveyId, i);
        imagePaths.add(permanentPath);
      }

      await offlineBox.put(surveyId, {
        'tree': tree.toJson(),
        'imagePaths': imagePaths,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      });
    } catch (e) {
      print('Error storing offline survey: $e');
    }
  }

  // Copy image to permanent storage
  Future<String> _copyImageToPermanentStorage(File image, String surveyId, int index) async {
    try {
      final directory = await _getOfflineStorageDirectory();
      final fileName = '${surveyId}_$index.jpg';
      final permanentFile = File('${directory.path}/$fileName');

      await image.copy(permanentFile.path);
      return permanentFile.path;
    } catch (e) {
      throw Exception('Failed to copy image to permanent storage: $e');
    }
  }

  // Get offline storage directory
  Future<Directory> _getOfflineStorageDirectory() async {
    try {
      // Use path_provider to get the proper app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${appDocDir.path}/offline_surveys');

      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }
      return offlineDir;
    } catch (e) {
      throw Exception('Failed to create offline storage directory: $e');
    }
  }

  // Sync offline surveys
  Future<void> syncOfflineSurveys() async {
    try {
      final offlineBox = await Hive.openBox('offline_surveys');
      final surveys = offlineBox.values.where((survey) => survey['synced'] != true).toList();

      for (final surveyData in surveys) {
        try {
          final tree = Tree.fromJson(surveyData['tree']);
          final imagePaths = List<String>.from(surveyData['imagePaths']);
          final images = imagePaths.map((path) => File(path)).toList();

          final result = await submitSurvey(tree, images);

          if (result['success'] == true) {
            // Mark as synced
            surveyData['synced'] = true;
            await offlineBox.put(surveyData.key, surveyData);

            // Clean up image files
            for (final image in images) {
              try {
                await image.delete();
              } catch (e) {
                // Ignore deletion errors
              }
            }
          }
        } catch (e) {
          print('Failed to sync survey: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to sync offline surveys: $e');
    }
  }

  // Get offline surveys count
  Future<int> getOfflineSurveysCount() async {
    try {
      final offlineBox = await Hive.openBox('offline_surveys');
      return offlineBox.values.where((survey) => survey['synced'] != true).length;
    } catch (e) {
      return 0;
    }
  }

  // Clear synced offline surveys
  Future<void> clearSyncedSurveys() async {
    try {
      final offlineBox = await Hive.openBox('offline_surveys');
      final keysToDelete = <dynamic>[];

      for (final entry in offlineBox.toMap().entries) {
        if (entry.value['synced'] == true) {
          keysToDelete.add(entry.key);
        }
      }

      for (final key in keysToDelete) {
        await offlineBox.delete(key);
      }
    } catch (e) {
      print('Error clearing synced surveys: $e');
    }
  }

  // Export survey data
  Future<String> exportSurveyData({
    required List<Map<String, dynamic>> surveys,
    String format = 'csv',
    List<String>? fields,
  }) async {
    try {
      if (format.toLowerCase() == 'csv') {
        return _exportSurveysToCSV(surveys, fields);
      } else if (format.toLowerCase() == 'json') {
        return _exportSurveysToJSON(surveys, fields);
      } else {
        throw Exception('Unsupported export format: $format');
      }
    } catch (e) {
      throw Exception('Failed to export survey data: $e');
    }
  }

  // Export surveys to CSV
  String _exportSurveysToCSV(List<Map<String, dynamic>> surveys, List<String>? fields) {
    final selectedFields = fields ?? [
      'id', 'species', 'localName', 'height', 'girth', 'age',
      'health', 'ward', 'surveyorId', 'timestamp'
    ];

    final csvLines = <String>[];
    csvLines.add(selectedFields.join(','));

    for (final survey in surveys) {
      final row = selectedFields.map((field) {
        return survey[field]?.toString() ?? '';
      }).join(',');
      csvLines.add(row);
    }

    return csvLines.join('\n');
  }

  // Export surveys to JSON
  String _exportSurveysToJSON(List<Map<String, dynamic>> surveys, List<String>? fields) {
    if (fields == null) {
      return jsonEncode(surveys);
    }

    final filteredSurveys = surveys.map((survey) {
      final filteredSurvey = <String, dynamic>{};
      for (final field in fields) {
        if (survey.containsKey(field)) {
          filteredSurvey[field] = survey[field];
        }
      }
      return filteredSurvey;
    }).toList();

    return jsonEncode(filteredSurveys);
  }
}
