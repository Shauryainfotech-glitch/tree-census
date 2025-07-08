# TMC Tree Census Flutter App

A comprehensive Flutter application for tree census management developed for Thane Municipal Corporation (TMC) with AI-powered features for species identification, health monitoring, and predictive analytics.

## 🌳 Overview

This Flutter application implements the Maharashtra (Urban Area) Protection & Preservation of Trees Act 1975, providing a complete digital solution for tree census management with cutting-edge AI technology and offline capabilities.

## ✨ Features

### 🤖 AI-Powered Capabilities
- **Smart Species Identification**: AI-powered tree species identification from photos
- **Health Assessment**: Automated health analysis and predictive maintenance recommendations
- **Growth Prediction**: AI models predict tree growth patterns and maintenance needs
- **Risk Assessment**: Intelligent risk evaluation for tree safety

### 📱 Core Functionality
- **Digital Tree Census**: Complete inventory with GPS/GIS mapping
- **Mobile Survey App**: Offline-capable field data collection
- **Request Management**: Online tree pruning/cutting permission system
- **Heritage Tree Protection**: Special monitoring for trees aged 50+ years
- **Multi-User Access**: Role-based access for citizens, surveyors, and administrators

### 🔧 Technical Features
- **Offline Support**: Full offline functionality with auto-sync
- **Real-time Dashboard**: Comprehensive analytics and reporting
- **Responsive Design**: Mobile-first, accessible interface
- **Error Handling**: Robust error boundaries and recovery
- **Performance Optimized**: Fast loading with efficient state management

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android device/emulator or iOS device/simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/tmc/tree-census-flutter.git
   cd tmc-tree-census-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate model files**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure environment**
   - Update API endpoints in `lib/utils/constants.dart`
   - Add Google Maps API key in `android/app/src/main/AndroidManifest.xml`
   - Configure iOS permissions in `ios/Runner/Info.plist`

5. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── tree.dart               # Tree model with Hive annotations
│   ├── user.dart               # User model with roles
│   └── tree_request.dart       # Request model
├── providers/                   # State management (Provider pattern)
│   ├── auth_provider.dart      # Authentication state
│   ├── tree_provider.dart      # Tree data management
│   ├── request_provider.dart   # Request management
│   ├── survey_provider.dart    # Survey state management
│   └── dashboard_provider.dart # Dashboard analytics
├── screens/                     # UI screens
│   ├── splash_screen.dart      # App splash screen
│   ├── auth/                   # Authentication screens
│   ├── home/                   # Home screen
│   ├── dashboard/              # Analytics dashboard
│   ├── trees/                  # Tree search and details
│   ├── survey/                 # Field survey screens
│   ├── requests/               # Request management
│   └── admin/                  # Admin panel
├── services/                    # Business logic and API calls
│   ├── auth_service.dart       # Authentication API
│   ├── tree_service.dart       # Tree data API
│   ├── location_service.dart   # GPS and location services
│   ├── camera_service.dart     # Camera integration
│   └── ai_service.dart         # AI/ML integration
├── utils/                       # Utilities and constants
│   ├── constants.dart          # App constants and configuration
│   ├── theme.dart              # Material Design theme
│   └── helpers.dart            # Helper functions
└── widgets/                     # Reusable UI components
    ├── common/                 # Common widgets
    ├── forms/                  # Form components
    └── charts/                 # Chart widgets
```

## 🛠️ Configuration

### Environment Variables

Create environment-specific configuration in `lib/utils/constants.dart`:

```dart
class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.thanecity.gov.in/tree-census';
  static const String aiServiceUrl = 'https://ai.thanecity.gov.in/v1';
  
  // Maps
  static const String mapApiKey = 'your_google_maps_api_key_here';
  
  // Default Location (Thane, Maharashtra)
  static const double defaultLatitude = 19.2183;
  static const double defaultLongitude = 72.9781;
}
```

### Android Configuration

Add permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<application>
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

### iOS Configuration

Add permissions in `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to record tree locations during surveys.</string>
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos of trees during surveys.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select tree images.</string>
```

## 📱 Usage Guide

### For Citizens
1. **Search Trees**: Find trees in your area using the search functionality
2. **Submit Requests**: Apply for tree pruning/cutting permissions online
3. **Track Status**: Monitor your request status in real-time

### For Surveyors
1. **Field Survey**: Use the mobile-optimized survey module
2. **Offline Mode**: Collect data without internet connectivity
3. **AI Assistance**: Get species identification and health assessment help
4. **Auto-Sync**: Data automatically syncs when online

### For Administrators
1. **Dashboard**: Monitor system-wide statistics and trends
2. **Request Management**: Review and approve/reject citizen requests
3. **User Management**: Manage surveyor accounts and permissions
4. **Data Export**: Generate reports and export data

## 🤖 AI Features

### Species Identification
- Upload tree photos for automatic species identification
- High accuracy with confidence scoring
- Alternative species suggestions
- Integration with field survey workflow

### Health Assessment
- Automated health status evaluation
- Disease detection and risk assessment
- Maintenance recommendations
- Predictive analytics for tree care

### Smart Recommendations
- Context-aware suggestions based on current screen
- Maintenance scheduling optimization
- Resource allocation insights
- Growth pattern analysis

## 📊 Data Management

### Tree Census Criteria
- Trees with girth ≥ 10 cm
- Trees with height ≥ 3 meters
- All land types included
- Heritage trees (age >50 years) specially marked

### Data Collection
- GPS coordinates for precise location
- Comprehensive tree attributes
- Photo documentation
- Health and condition assessment
- Ownership and land use information

### Offline Capabilities
- Full offline data collection using Hive database
- Automatic synchronization when online
- Conflict resolution for concurrent edits
- Data integrity validation

## 🔒 Security & Privacy

- Role-based access control with Provider pattern
- Local data encryption using Hive
- Secure API communication
- Input validation and sanitization
- Error handling and logging

## 📈 Performance

- Optimized for mobile devices
- Efficient state management with Provider
- Image compression and caching
- Lazy loading for large datasets
- Background sync capabilities

## 🧪 Testing

Run tests using:

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

## 📦 Building

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter/Dart best practices
- Use Provider for state management
- Add tests for new features
- Ensure offline functionality
- Update documentation

## 🐛 Troubleshooting

### Common Issues

**Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build
```

**Location Issues**
- Ensure location permissions are granted
- Check GPS is enabled on device
- Verify location services in app settings

**Camera Issues**
- Grant camera permissions
- Check camera hardware availability
- Ensure adequate storage space

### Getting Help
- Check the [Issues](https://github.com/tmc/tree-census-flutter/issues) page
- Contact: treeauthority@thanecity.gov.in
- Phone: +91 22 2536 2000

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thane Municipal Corporation Garden Department
- Maharashtra State Tree Authority
- Flutter and Dart communities
- Open source contributors

## 📞 Contact

**Thane Municipal Corporation**
- Email: treeauthority@thanecity.gov.in
- Phone: +91 22 2536 2000
- Website: www.thanecity.gov.in
- Address: Garden Department, TMC, Thane

---

**Built with ❤️ for urban forest conservation using Flutter**

*This project supports the UN Sustainable Development Goals, particularly Goal 11 (Sustainable Cities and Communities) and Goal 15 (Life on Land).*

## 🔄 Version History

- **v1.0.0** - Initial release with core features
  - User authentication and role management
  - Tree search and survey functionality
  - Request submission and tracking
  - Offline data collection
  - Basic AI integration

## 🚧 Roadmap

- **v1.1.0** - Enhanced AI features
- **v1.2.0** - Advanced analytics and reporting
- **v1.3.0** - Multi-language support
- **v2.0.0** - IoT sensor integration
# tree-census
