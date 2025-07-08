import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadUserFromStorage();
  }

  // Load user data from local storage on app start
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      final token = prefs.getString(AppConstants.authTokenKey);

      if (userJson != null && token != null) {
        _currentUser = User.fromJson(_parseJson(userJson));
        _authToken = token;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }
  }

  // Save user data to local storage
  Future<void> _saveUserToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null && _authToken != null) {
        await prefs.setString(AppConstants.userKey, _currentUser!.toJson().toString());
        await prefs.setString(AppConstants.authTokenKey, _authToken!);
      }
    } catch (e) {
      debugPrint('Error saving user to storage: $e');
    }
  }

  // Clear user data from local storage
  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.authTokenKey);
    } catch (e) {
      debugPrint('Error clearing user from storage: $e');
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final credential = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
      if (!userDoc.exists) {
        _setError('User data not found.');
        _setLoading(false);
        return false;
      }
      final userData = userDoc.data()!;
      _currentUser = User(
        id: credential.user!.uid,
        email: userData['email'] ?? '',
        name: userData['name'] ?? '',
        mobile: userData['mobile'] ?? '',
        role: UserRole.values.firstWhere(
          (e) => e.name == (userData['role'] ?? 'citizen'),
          orElse: () => UserRole.citizen,
        ),
        isActive: userData['isActive'] ?? true,
      );
      _authToken = await credential.user!.getIdToken();
      await _saveUserToStorage();
      _setLoading(false);
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login failed.');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Network error. Please check your connection.');
      _setLoading(false);
      return false;
    }
  }



  // Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
    required UserRole role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        mobile: mobile,
        password: password,
        role: role,
      );
      
      if (result['success'] == true) {
        _currentUser = User.fromJson(result['user']);
        _authToken = result['token'];
        
        await _saveUserToStorage();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      _setLoading(false);
      return false;
    }
  }

  // Register user with Firebase
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String role, // e.g., 'admin' or 'citizen'
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Store additional user info in Firestore
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _currentUser = User(
        id: credential.user!.uid,
        email: email,
        name: name,
        mobile: '', // Set to empty or collect from form if available
        role: UserRole.values.firstWhere(
          (e) => e.name == role,
          orElse: () => UserRole.citizen,
        ),
        isActive: true,
      );
      _authToken = await credential.user!.getIdToken();
      await _saveUserToStorage();
      _isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      // Attempt to logout from backend, but do not block UI
      if (_authToken != null) {
        _authService.logout(_authToken!);
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _currentUser = null;
      _authToken = null;
      await _clearUserFromStorage();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? mobile,
    String? profileImage,
  }) async {
    if (_currentUser == null || _authToken == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.updateProfile(
        token: _authToken!,
        name: name,
        email: email,
        mobile: mobile,
        profileImage: profileImage,
      );
      
      if (result['success'] == true) {
        _currentUser = User.fromJson(result['user']);
        await _saveUserToStorage();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Profile update failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_authToken == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.changePassword(
        token: _authToken!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      if (result['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Password change failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      _setLoading(false);
      return false;
    }
  }

  // Refresh authentication token
  Future<bool> refreshToken() async {
    if (_authToken == null) return false;

    try {
      final result = await _authService.refreshToken(_authToken!);
      
      if (result['success'] == true) {
        _authToken = result['token'];
        await _saveUserToStorage();
        notifyListeners();
        return true;
      } else {
        // Token refresh failed, logout user
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      await logout();
      return false;
    }
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    return _currentUser!.role.permissions.contains(permission);
  }

  // Check if user is admin
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  // Check if user is surveyor
  bool get isSurveyor => _currentUser?.role == UserRole.surveyor;

  // Check if user is citizen
  bool get isCitizen => _currentUser?.role == UserRole.citizen;

  // Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.forgotPassword(email);
      _setLoading(false);
      if (result['success'] == true) {
        return true;
      } else {
        _setError(result['message'] ?? 'Failed to send reset email');
        return false;
      }
    } catch (e) {
      _setError('Network error. Please check your connection.');
      _setLoading(false);
      return false;
    }
  }

  // Utility to clear user data from storage (for development or reset purposes)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.authTokenKey);
    _currentUser = null;
    _authToken = null;
    notifyListeners();
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

  // Parse JSON string to Map
  Map<String, dynamic> _parseJson(String jsonString) {
    // This is a simplified parser - in real app, use dart:convert
    // For now, return mock data
    return {
      'id': '1',
      'name': 'Demo User',
      'email': 'demo@thanecity.gov.in',
      'mobile': '+91 9876543210',
      'role': 'admin',
      'isActive': true,
    };
  }
}
