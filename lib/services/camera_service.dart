import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';

class CameraService {
  static List<CameraDescription>? _cameras;
  CameraController? _controller;
  final ImagePicker _picker = ImagePicker();

  // Initialize cameras
  static Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  // Get available cameras
  static List<CameraDescription>? get cameras => _cameras;

  // Check camera permission
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Check storage permission
  Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Initialize camera controller
  Future<CameraController?> initializeCamera({
    CameraLensDirection direction = CameraLensDirection.back,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available');
    }

    // Find camera with specified direction
    CameraDescription? camera;
    try {
      camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == direction,
      );
    } catch (e) {
      // If specified direction not found, use first available camera
      camera = _cameras!.first;
    }

    _controller = CameraController(
      camera,
      resolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      return _controller;
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  // Take photo using camera
  Future<File?> takePhoto() async {
    try {
      // Check camera permission
      if (!await checkCameraPermission()) {
        final granted = await requestCameraPermission();
        if (!granted) {
          throw Exception('Camera permission denied');
        }
      }

      // Use image picker for simplicity
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        // Compress and optimize image
        final optimizedFile = await _optimizeImage(imageFile);
        
        return optimizedFile;
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      // Check storage permission
      if (!await checkStoragePermission()) {
        final granted = await requestStoragePermission();
        if (!granted) {
          throw Exception('Storage permission denied');
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        // Compress and optimize image
        final optimizedFile = await _optimizeImage(imageFile);
        
        return optimizedFile;
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      if (!await checkStoragePermission()) {
        final granted = await requestStoragePermission();
        if (!granted) {
          throw Exception('Storage permission denied');
        }
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.length > maxImages) {
        throw Exception('Maximum $maxImages images allowed');
      }

      final List<File> optimizedFiles = [];
      
      for (final image in images) {
        final File imageFile = File(image.path);
        final optimizedFile = await _optimizeImage(imageFile);
        optimizedFiles.add(optimizedFile);
      }
      
      return optimizedFiles;
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  // Optimize image (compress and resize)
  Future<File> _optimizeImage(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large
      if (image.width > 1920 || image.height > 1080) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1080 : null,
        );
      }

      // Compress image
      final compressedBytes = img.encodeJpg(image, quality: 85);
      
      // Check file size
      if (compressedBytes.length > AppConstants.maxImageSize) {
        // Further compress if still too large
        final furtherCompressed = img.encodeJpg(image, quality: 70);
        
        if (furtherCompressed.length > AppConstants.maxImageSize) {
          throw Exception('Image too large even after compression');
        }
        
        return await _saveOptimizedImage(furtherCompressed, imageFile.path);
      }
      
      return await _saveOptimizedImage(compressedBytes, imageFile.path);
    } catch (e) {
      throw Exception('Failed to optimize image: $e');
    }
  }

  // Save optimized image
  Future<File> _saveOptimizedImage(List<int> bytes, String originalPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'optimized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final optimizedFile = File('${directory.path}/$fileName');
      
      await optimizedFile.writeAsBytes(bytes);
      
      // Delete original file if it's in temp directory
      if (originalPath.contains('cache') || originalPath.contains('tmp')) {
        try {
          await File(originalPath).delete();
        } catch (e) {
          // Ignore deletion errors
        }
      }
      
      return optimizedFile;
    } catch (e) {
      throw Exception('Failed to save optimized image: $e');
    }
  }

  // Capture image with camera controller
  Future<File?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      final XFile image = await _controller!.takePicture();
      final File imageFile = File(image.path);
      
      // Optimize the captured image
      final optimizedFile = await _optimizeImage(imageFile);
      
      return optimizedFile;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  // Start video recording
  Future<void> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    if (_controller!.value.isRecordingVideo) {
      return; // Already recording
    }

    try {
      await _controller!.startVideoRecording();
    } catch (e) {
      throw Exception('Failed to start video recording: $e');
    }
  }

  // Stop video recording
  Future<File?> stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    if (!_controller!.value.isRecordingVideo) {
      return null; // Not recording
    }

    try {
      final XFile video = await _controller!.stopVideoRecording();
      return File(video.path);
    } catch (e) {
      throw Exception('Failed to stop video recording: $e');
    }
  }

  // Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      throw Exception('Multiple cameras not available');
    }

    final currentDirection = _controller?.description.lensDirection;
    final newDirection = currentDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    await disposeCamera();
    await initializeCamera(direction: newDirection);
  }

  // Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      throw Exception('Failed to set flash mode: $e');
    }
  }

  // Set zoom level
  Future<void> setZoomLevel(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      final maxZoom = await _controller!.getMaxZoomLevel();
      final minZoom = await _controller!.getMinZoomLevel();
      
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
    } catch (e) {
      throw Exception('Failed to set zoom level: $e');
    }
  }

  // Get camera info
  Map<String, dynamic> getCameraInfo() {
    if (_controller == null) {
      return {};
    }

    return {
      'isInitialized': _controller!.value.isInitialized,
      'isRecording': _controller!.value.isRecordingVideo,
      'flashMode': _controller!.value.flashMode.toString(),
      'direction': _controller!.description.lensDirection.toString(),
      'sensorOrientation': _controller!.description.sensorOrientation,
    };
  }

  // Validate image file
  bool isValidImageFile(File file) {
    try {
      final extension = file.path.split('.').last.toLowerCase();
      return AppConstants.allowedImageFormats.contains(extension);
    } catch (e) {
      return false;
    }
  }

  // Get image metadata
  Future<Map<String, dynamic>> getImageMetadata(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final fileStat = await imageFile.stat();
      
      return {
        'width': image.width,
        'height': image.height,
        'size': fileStat.size,
        'sizeFormatted': _formatFileSize(fileStat.size),
        'created': fileStat.modified,
        'format': imageFile.path.split('.').last.toUpperCase(),
      };
    } catch (e) {
      throw Exception('Failed to get image metadata: $e');
    }
  }

  // Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Create thumbnail
  Future<File> createThumbnail(File imageFile, {int size = 200}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Create square thumbnail
      final thumbnail = img.copyResizeCropSquare(image, size: size);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final thumbnailFile = File('${directory.path}/thumbnails/$fileName');
      
      // Create thumbnails directory if it doesn't exist
      await thumbnailFile.parent.create(recursive: true);
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      
      return thumbnailFile;
    } catch (e) {
      throw Exception('Failed to create thumbnail: $e');
    }
  }

  // Dispose camera controller
  Future<void> disposeCamera() async {
    try {
      await _controller?.dispose();
      _controller = null;
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  // Check if camera is available
  bool get isCameraAvailable => _cameras != null && _cameras!.isNotEmpty;

  // Check if camera is initialized
  bool get isCameraInitialized => 
      _controller != null && _controller!.value.isInitialized;

  // Get current camera controller
  CameraController? get controller => _controller;
}
