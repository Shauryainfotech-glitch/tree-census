class AppConstants {
  // App Information
  static const String appName = 'TMC Tree Census';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered Tree Management System';
  static const String organization = 'Thane Municipal Corporation';
  
  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8000'; // Change 8000 to your backend's port if needed
  static const String aiServiceUrl = 'https://ai.thanecity.gov.in/v1';
  static const String mapApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Default Location (Thane, Maharashtra)
  static const double defaultLatitude = 19.2183;
  static const double defaultLongitude = 72.9781;
  static const double defaultZoom = 12.0;
  
  // Tree Census Criteria
  static const double minTreeGirth = 10.0; // cm
  static const double minTreeHeight = 3.0; // meters
  static const int heritageTreeAge = 50; // years
  
  // File Upload Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx'];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Duration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration shortCacheExpiry = Duration(hours: 1);
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Local Storage Keys
  static const String userKey = 'user_data';
  static const String authTokenKey = 'auth_token';
  static const String settingsKey = 'app_settings';
  static const String offlineDataKey = 'offline_data';
  static const String lastSyncKey = 'last_sync';
  
  // Hive Box Names
  static const String treesBox = 'trees';
  static const String requestsBox = 'requests';
  static const String usersBox = 'users';
  static const String surveysBox = 'surveys';
  static const String settingsBox = 'settings';
  
  // Error Messages
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String authError = 'Authentication failed. Please login again.';
  static const String permissionError = 'Permission denied. Please grant required permissions.';
  static const String locationError = 'Unable to get location. Please enable location services.';
  static const String cameraError = 'Camera access denied. Please enable camera permission.';
  static const String storageError = 'Storage access denied. Please enable storage permission.';
  
  // Success Messages
  static const String loginSuccess = 'Login successful';
  static const String logoutSuccess = 'Logout successful';
  static const String saveSuccess = 'Data saved successfully';
  static const String uploadSuccess = 'Upload completed successfully';
  static const String syncSuccess = 'Data synchronized successfully';
  
  // Validation Messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidMobile = 'Please enter a valid mobile number';
  static const String invalidAadhar = 'Please enter a valid Aadhar number';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
  
  // Tree Species (Common ones in Maharashtra)
  static const List<String> commonTreeSpecies = [
    'Mangifera indica (Mango)',
    'Ficus religiosa (Peepal)',
    'Ficus benghalensis (Banyan)',
    'Azadirachta indica (Neem)',
    'Tamarindus indica (Tamarind)',
    'Polyalthia longifolia (Ashoka)',
    'Delonix regia (Gulmohar)',
    'Cassia fistula (Amaltas)',
    'Terminalia arjuna (Arjun)',
    'Syzygium cumini (Jamun)',
    'Alstonia scholaris (Saptaparni)',
    'Bombax ceiba (Semal)',
    'Lagerstroemia speciosa (Jarul)',
    'Pongamia pinnata (Karanj)',
    'Madhuca longifolia (Mahua)',
  ];
  
  // Ward Names (Thane Municipal Corporation)
  static const List<String> thaneWards = [
    'Ward 1 - Naupada',
    'Ward 2 - Kopri',
    'Ward 3 - Diva',
    'Ward 4 - Mumbra',
    'Ward 5 - Kausa',
    'Ward 6 - Owale',
    'Ward 7 - Ghodbunder',
    'Ward 8 - Kasarvadavali',
    'Ward 9 - Majiwada',
    'Ward 10 - Wagle Estate',
    'Ward 11 - Vartak Nagar',
    'Ward 12 - Hiranandani',
    'Ward 13 - Kapurbawdi',
    'Ward 14 - Manpada',
    'Ward 15 - Teen Hath Naka',
  ];
  
  // Health Status Options
  static const List<String> healthStatusOptions = [
    'Healthy',
    'Diseased',
    'Mechanically Damaged',
    'Poor',
    'Uprooted',
  ];
  
  // Ownership Types
  static const List<String> ownershipTypes = [
    'Government',
    'Private',
    'Garden',
    'Road Divider',
  ];
  
  // Request Types
  static const List<String> requestTypes = [
    'Tree Pruning',
    'Tree Cutting',
    'Tree Transplanting',
    'Tree Treatment',
  ];
  
  // AI Confidence Thresholds
  static const double minAIConfidence = 0.7;
  static const double highAIConfidence = 0.9;
  
  // Map Configuration
  static const double mapZoomMin = 8.0;
  static const double mapZoomMax = 20.0;
  static const double clusterDistance = 50.0;
  
  // Notification Types
  static const String notificationTypeInfo = 'info';
  static const String notificationTypeSuccess = 'success';
  static const String notificationTypeWarning = 'warning';
  static const String notificationTypeError = 'error';
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Contact Information
  static const String supportEmail = 'treeauthority@thanecity.gov.in';
  static const String supportPhone = '+91 22 2536 2000';
  static const String websiteUrl = 'https://www.thanecity.gov.in';
  static const String officeAddress = 'Garden Department, TMC, Thane';
  
  // Legal Information
  static const String legalAct = 'Maharashtra (Urban Area) Protection & Preservation of Trees Act 1975';
  static const String pilReference = 'HC Bombay PIL 93/2009';
  
  // Feature Flags
  static const bool enableAIFeatures = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = true;
  
  // Survey Configuration
  static const int maxImagesPerTree = 5;
  static const int maxNotesLength = 500;
  static const double gpsAccuracyThreshold = 10.0; // meters
  
  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);
}

class ApiEndpoints {
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';
  
  static const String trees = '/trees';
  static const String treeById = '/trees/{id}';
  static const String treeSearch = '/trees/search';
  static const String treesByWard = '/trees/ward/{ward}';
  static const String heritageTree = '/trees/heritage';
  
  static const String requests = '/requests';
  static const String requestById = '/requests/{id}';
  static const String requestsByUser = '/requests/user/{userId}';
  static const String requestApproval = '/requests/{id}/approve';
  static const String requestRejection = '/requests/{id}/reject';
  
  static const String surveys = '/surveys';
  static const String surveySubmit = '/surveys/submit';
  static const String surveysByUser = '/surveys/user/{userId}';
  
  static const String dashboard = '/dashboard/stats';
  static const String reports = '/reports';
  static const String analytics = '/analytics';
  
  static const String aiSpeciesIdentification = '/ai/species-identification';
  static const String aiHealthAssessment = '/ai/health-assessment';
  static const String aiRiskAnalysis = '/ai/risk-analysis';
  
  static const String fileUpload = '/files/upload';
  static const String fileDownload = '/files/{id}';
  
  static const String notifications = '/notifications';
  static const String notificationMarkRead = '/notifications/{id}/read';
}

class PermissionTypes {
  static const String camera = 'camera';
  static const String location = 'location';
  static const String storage = 'storage';
  static const String microphone = 'microphone';
  static const String notification = 'notification';
}

class DatabaseTables {
  static const String trees = 'trees';
  static const String requests = 'tree_requests';
  static const String users = 'users';
  static const String surveys = 'surveys';
  static const String notifications = 'notifications';
  static const String sync_queue = 'sync_queue';
}
