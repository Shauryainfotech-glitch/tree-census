import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/constants.dart';

class LocationService {
  // Get current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. Please grant location permission.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable location permission in app settings.',
      );
    }

    // Get current position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check GPS accuracy
      if (position.accuracy > AppConstants.gpsAccuracyThreshold) {
        throw Exception(
          'GPS accuracy is poor (${position.accuracy.toStringAsFixed(1)}m). Please try again in an open area.',
        );
      }

      return position;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Calculate bearing between two points
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Get address from coordinates (reverse geocoding)
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final addressComponents = <String>[];

        if (placemark.name != null && placemark.name!.isNotEmpty) {
          addressComponents.add(placemark.name!);
        }
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          addressComponents.add(placemark.street!);
        }
        if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          addressComponents.add(placemark.subLocality!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressComponents.add(placemark.locality!);
        }
        if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
          addressComponents.add(placemark.administrativeArea!);
        }
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          addressComponents.add(placemark.postalCode!);
        }

        return addressComponents.join(', ');
      } else {
        return 'Unknown location';
      }
    } catch (e) {
      return 'Unable to get address';
    }
  }

  // Get coordinates from address (forward geocoding)
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
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
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if location is within Thane city bounds
  bool isWithinThaneCity(double latitude, double longitude) {
    // Approximate bounds for Thane city
    const double northBound = 19.3;
    const double southBound = 19.1;
    const double eastBound = 73.1;
    const double westBound = 72.8;

    return latitude >= southBound &&
           latitude <= northBound &&
           longitude >= westBound &&
           longitude <= eastBound;
  }

  // Get ward from coordinates
  String getWardFromCoordinates(double latitude, double longitude) {
    // This is a simplified implementation
    // In a real app, you would use a proper ward boundary service
    
    if (!isWithinThaneCity(latitude, longitude)) {
      return 'Outside Thane';
    }

    // Simple grid-based ward assignment for demo
    final latIndex = ((latitude - 19.1) / 0.02).floor();
    final lngIndex = ((longitude - 72.8) / 0.03).floor();
    final wardIndex = (latIndex * 10 + lngIndex) % AppConstants.thaneWards.length;
    
    return AppConstants.thaneWards[wardIndex];
  }

  // Start location tracking
  Stream<Position> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
    Duration interval = const Duration(seconds: 5),
  }) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Check location permission status
  Future<LocationPermissionStatus> getLocationPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  // Request location permission
  Future<LocationPermissionStatus> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get location accuracy description
  String getAccuracyDescription(double accuracy) {
    if (accuracy <= 5) {
      return 'Excellent (${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy <= 10) {
      return 'Good (${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy <= 20) {
      return 'Fair (${accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Poor (${accuracy.toStringAsFixed(1)}m)';
    }
  }

  // Format coordinates for display
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Convert coordinates to degrees, minutes, seconds format
  String formatCoordinatesDMS(double latitude, double longitude) {
    String convertToDMS(double coordinate, bool isLatitude) {
      final direction = isLatitude 
          ? (coordinate >= 0 ? 'N' : 'S')
          : (coordinate >= 0 ? 'E' : 'W');
      
      final absolute = coordinate.abs();
      final degrees = absolute.floor();
      final minutes = ((absolute - degrees) * 60).floor();
      final seconds = ((absolute - degrees - minutes / 60) * 3600);
      
      return '${degrees}°${minutes}\'${seconds.toStringAsFixed(2)}"$direction';
    }

    final latDMS = convertToDMS(latitude, true);
    final lngDMS = convertToDMS(longitude, false);
    
    return '$latDMS, $lngDMS';
  }

  // Get distance description
  String getDistanceDescription(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  // Get bearing description
  String getBearingDescription(double bearing) {
    final directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    
    final index = ((bearing + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  // Validate coordinates
  bool isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 && 
           latitude <= 90 && 
           longitude >= -180 && 
           longitude <= 180;
  }

  // Get default location (Thane city center)
  Position getDefaultLocation() {
    return Position(
      latitude: AppConstants.defaultLatitude,
      longitude: AppConstants.defaultLongitude,
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
}

enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
}

extension LocationPermissionStatusExtension on LocationPermissionStatus {
  String get description {
    switch (this) {
      case LocationPermissionStatus.denied:
        return 'Location permission denied';
      case LocationPermissionStatus.deniedForever:
        return 'Location permission permanently denied';
      case LocationPermissionStatus.whileInUse:
        return 'Location permission granted while app is in use';
      case LocationPermissionStatus.always:
        return 'Location permission granted always';
    }
  }

  bool get isGranted {
    return this == LocationPermissionStatus.whileInUse || 
           this == LocationPermissionStatus.always;
  }
}
