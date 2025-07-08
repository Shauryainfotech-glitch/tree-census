import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/tree.dart';
import '../models/user.dart';
import '../services/survey_service.dart';
import '../services/location_service.dart';
import '../services/camera_service.dart';
import 'package:geolocator/geolocator.dart';

class SurveyProvider extends ChangeNotifier {
  // Current survey data
  String? _scientificName;
  String? _localName;
  double? _height;
  double? _girth;
  int? _age;
  TreeHealth? _healthCondition;
  TreeOwnership? _ownership;
  bool _isHeritage = false;
  double? _canopy;
  String? _ward;
  Position? _location;
  List<File> _images = [];
  String? _notes;

  // Survey state
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSurveyActive = false;
  DateTime? _surveyStartTime;
  String? _surveyId;

  // Location and camera services
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();
  final SurveyService _surveyService = SurveyService();

  // Getters
  String? get scientificName => _scientificName;
  String? get localName => _localName;
  double? get height => _height;
  double? get girth => _girth;
  int? get age => _age;
  TreeHealth? get healthCondition => _healthCondition;
  TreeOwnership? get ownership => _ownership;
  bool get isHeritage => _isHeritage;
  double? get canopy => _canopy;
  String? get ward => _ward;
  Position? get location => _location;
  List<File> get images => _images;
  String? get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSurveyActive => _isSurveyActive;
  DateTime? get surveyStartTime => _surveyStartTime;
  String? get surveyId => _surveyId;

  // Check if survey data is valid
  bool get isValidSurvey {
    return _scientificName != null &&
           _scientificName!.isNotEmpty &&
           _localName != null &&
           _localName!.isNotEmpty &&
           _height != null &&
           _height! > 0 &&
           _girth != null &&
           _girth! > 0 &&
           _age != null &&
           _age! > 0 &&
           _healthCondition != null &&
           _ownership != null &&
           _canopy != null &&
           _canopy! > 0 &&
           _ward != null &&
           _ward!.isNotEmpty &&
           _location != null;
  }

  // Start new survey
  Future<void> startSurvey() async {
    _clearSurveyData();
    _isSurveyActive = true;
    _surveyStartTime = DateTime.now();
    _surveyId = 'SURVEY_${DateTime.now().millisecondsSinceEpoch}';
    
    // Get current location
    await getCurrentLocation();
    
    notifyListeners();
  }

  // End current survey
  void endSurvey() {
    _isSurveyActive = false;
    _surveyStartTime = null;
    _surveyId = null;
    notifyListeners();
  }

  // Clear all survey data
  void _clearSurveyData() {
    _scientificName = null;
    _localName = null;
    _height = null;
    _girth = null;
    _age = null;
    _healthCondition = null;
    _ownership = null;
    _isHeritage = false;
    _canopy = null;
    _ward = null;
    _location = null;
    _images.clear();
    _notes = null;
    _clearError();
  }

  // Update survey fields
  void updateScientificName(String name) {
    _scientificName = name;
    notifyListeners();
  }

  void updateLocalName(String name) {
    _localName = name;
    notifyListeners();
  }

  void updateHeight(double height) {
    _height = height;
    notifyListeners();
  }

  void updateGirth(double girth) {
    _girth = girth;
    notifyListeners();
  }

  void updateAge(int age) {
    _age = age;
    notifyListeners();
  }

  void updateHealthCondition(TreeHealth health) {
    _healthCondition = health;
    notifyListeners();
  }

  void updateOwnership(TreeOwnership ownership) {
    _ownership = ownership;
    notifyListeners();
  }

  void updateHeritage(bool heritage) {
    _isHeritage = heritage;
    notifyListeners();
  }

  void updateCanopy(double canopy) {
    _canopy = canopy;
    notifyListeners();
  }

  void updateWard(String ward) {
    _ward = ward;
    notifyListeners();
  }

  void updateNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  // Location methods
  Future<void> getCurrentLocation() async {
    _setLoading(true);
    _clearError();

    try {
      _location = await _locationService.getCurrentPosition();
      
      // Auto-detect ward from location
      if (_location != null) {
        _ward = _locationService.getWardFromCoordinates(
          _location!.latitude,
          _location!.longitude,
        );
      }
      
      _setLoading(false);
      notifyListeners(); // Ensure UI updates with new location
    } catch (e) {
      _setError('Failed to get location: ${e.toString()}');
      _setLoading(false);
      notifyListeners(); // Also notify on error
    }
  }

  void updateLocation(Position position) {
    _location = position;
    _ward = _locationService.getWardFromCoordinates(
      position.latitude,
      position.longitude,
    );
    notifyListeners();
  }

  // Camera methods
  Future<void> takePhoto() async {
    try {
      final image = await _cameraService.takePhoto();
      if (image != null) {
        _images.add(image);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to take photo: ${e.toString()}');
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final image = await _cameraService.pickImageFromGallery();
      if (image != null) {
        _images.add(image);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to pick image: ${e.toString()}');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      notifyListeners();
    }
  }

  void clearImages() {
    _images.clear();
    notifyListeners();
  }

  // AI-powered species identification
  Future<void> identifySpeciesFromImage(File image) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _surveyService.identifySpecies(image);
      
      if (result['success'] == true) {
        _scientificName = result['species'];
        _localName = result['localName'];
        
        // Show confidence level to user
        final confidence = result['confidence'] as double;
        if (confidence < 0.8) {
          _setError('Species identification confidence is low (${(confidence * 100).toInt()}%). Please verify manually.');
        }
      } else {
        _setError('Failed to identify species: ${result['message']}');
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Species identification failed: ${e.toString()}');
      _setLoading(false);
    }
  }

  // AI-powered health assessment
  Future<void> assessTreeHealth(File image) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _surveyService.assessHealth(image);
      
      if (result['success'] == true) {
        final healthStatus = result['health'] as String;
        _healthCondition = TreeHealth.values.firstWhere(
          (h) => h.toString().split('.').last.toLowerCase() == healthStatus.toLowerCase(),
          orElse: () => TreeHealth.healthy,
        );
        
        // Add AI recommendations to notes
        final recommendations = result['recommendations'] as List<String>?;
        if (recommendations != null && recommendations.isNotEmpty) {
          final aiNotes = 'AI Health Assessment:\n${recommendations.join('\n')}';
          _notes = _notes != null ? '$_notes\n\n$aiNotes' : aiNotes;
        }
      } else {
        _setError('Failed to assess health: ${result['message']}');
      }
      
      _setLoading(false);
    } catch (e) {
      _setError('Health assessment failed: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Submit survey
  Future<bool> submitSurvey(String surveyorId) async {
    if (!isValidSurvey) {
      _setError('Please fill in all required fields');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Create tree object from survey data
      final tree = Tree(
        id: 'TEMP_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
        species: _scientificName!,
        localName: _localName!,
        lat: _location!.latitude,
        lng: _location!.longitude,
        height: _height!,
        girth: _girth!,
        age: _age!,
        heritage: _isHeritage,
        ward: _ward!,
        health: _healthCondition!,
        canopy: _canopy!,
        ownership: _ownership!,
        lastSurveyDate: DateTime.now(),
        surveyorId: surveyorId,
        notes: _notes,
      );

      // Submit survey with images
      final result = await _surveyService.submitSurvey(tree, _images);
      
      if (result['success'] == true) {
        // Clear survey data after successful submission
        _clearSurveyData();
        endSurvey();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to submit survey: ${result['message']}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Survey submission failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Save survey as draft
  Future<bool> saveDraft() async {
    try {
      final draftData = {
        'surveyId': _surveyId,
        'scientificName': _scientificName,
        'localName': _localName,
        'height': _height,
        'girth': _girth,
        'age': _age,
        'healthCondition': _healthCondition?.toString(),
        'ownership': _ownership?.toString(),
        'isHeritage': _isHeritage,
        'canopy': _canopy,
        'ward': _ward,
        'location': _location != null ? {
          'latitude': _location!.latitude,
          'longitude': _location!.longitude,
        } : null,
        'notes': _notes,
        'imagePaths': _images.map((img) => img.path).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _surveyService.saveDraft(draftData);
      return true;
    } catch (e) {
      _setError('Failed to save draft: ${e.toString()}');
      return false;
    }
  }

  // Load draft survey
  Future<bool> loadDraft(String draftId) async {
    _setLoading(true);
    _clearError();

    try {
      final draftData = await _surveyService.loadDraft(draftId);
      
      if (draftData != null) {
        _surveyId = draftData['surveyId'];
        _scientificName = draftData['scientificName'];
        _localName = draftData['localName'];
        _height = draftData['height'];
        _girth = draftData['girth'];
        _age = draftData['age'];
        
        if (draftData['healthCondition'] != null) {
          _healthCondition = TreeHealth.values.firstWhere(
            (h) => h.toString() == draftData['healthCondition'],
            orElse: () => TreeHealth.healthy,
          );
        }
        
        if (draftData['ownership'] != null) {
          _ownership = TreeOwnership.values.firstWhere(
            (o) => o.toString() == draftData['ownership'],
            orElse: () => TreeOwnership.government,
          );
        }
        
        _isHeritage = draftData['isHeritage'] ?? false;
        _canopy = draftData['canopy'];
        _ward = draftData['ward'];
        _notes = draftData['notes'];
        
        if (draftData['location'] != null) {
          final locationData = draftData['location'];
          _location = Position(
            latitude: locationData['latitude'],
            longitude: locationData['longitude'],
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        }
        
        // Load images
        final imagePaths = draftData['imagePaths'] as List<String>?;
        if (imagePaths != null) {
          _images = imagePaths.map((path) => File(path)).toList();
        }
        
        _isSurveyActive = true;
        _setLoading(false);
        return true;
      } else {
        _setError('Draft not found');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to load draft: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Get survey progress percentage
  int getSurveyProgress() {
    int completedFields = 0;
    const int totalFields = 11; // Total required fields

    if (_scientificName != null && _scientificName!.isNotEmpty) completedFields++;
    if (_localName != null && _localName!.isNotEmpty) completedFields++;
    if (_height != null && _height! > 0) completedFields++;
    if (_girth != null && _girth! > 0) completedFields++;
    if (_age != null && _age! > 0) completedFields++;
    if (_healthCondition != null) completedFields++;
    if (_ownership != null) completedFields++;
    if (_canopy != null && _canopy! > 0) completedFields++;
    if (_ward != null && _ward!.isNotEmpty) completedFields++;
    if (_location != null) completedFields++;
    if (_images.isNotEmpty) completedFields++;

    return ((completedFields / totalFields) * 100).round();
  }

  // Validate individual fields
  String? validateScientificName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Scientific name is required';
    }
    return null;
  }

  String? validateLocalName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Local name is required';
    }
    return null;
  }

  String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }
    final height = double.tryParse(value);
    if (height == null || height <= 0) {
      return 'Please enter a valid height';
    }
    if (height < 3.0) {
      return 'Height must be at least 3 meters for census criteria';
    }
    return null;
  }

  String? validateGirth(String? value) {
    if (value == null || value.isEmpty) {
      return 'Girth is required';
    }
    final girth = double.tryParse(value);
    if (girth == null || girth <= 0) {
      return 'Please enter a valid girth';
    }
    if (girth < 10.0) {
      return 'Girth must be at least 10 cm for census criteria';
    }
    return null;
  }

  String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0) {
      return 'Please enter a valid age';
    }
    return null;
  }

  String? validateCanopy(String? value) {
    if (value == null || value.isEmpty) {
      return 'Canopy spread is required';
    }
    final canopy = double.tryParse(value);
    if (canopy == null || canopy <= 0) {
      return 'Please enter a valid canopy spread';
    }
    return null;
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

  // Get location accuracy description
  String? getLocationAccuracy() {
    if (_location == null) return null;
    return _locationService.getAccuracyDescription(_location!.accuracy);
  }

  // Get formatted coordinates
  String? getFormattedCoordinates() {
    if (_location == null) return null;
    return _locationService.formatCoordinates(
      _location!.latitude,
      _location!.longitude,
    );
  }

  // Check if location is within Thane city
  bool isLocationValid() {
    if (_location == null) return false;
    return _locationService.isWithinThaneCity(
      _location!.latitude,
      _location!.longitude,
    );
  }
}
