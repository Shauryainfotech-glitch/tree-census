import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/tree.dart';
import '../../providers/survey_provider.dart';

class FieldSurveyScreen extends StatefulWidget {
  const FieldSurveyScreen({super.key});

  @override
  State<FieldSurveyScreen> createState() => _FieldSurveyScreenState();
}

class _FieldSurveyScreenState extends State<FieldSurveyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Location state
  bool _isGettingLocation = false;
  String? _locationError;

  // Form controllers
  final _scientificNameController = TextEditingController();
  final _localNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _girthController = TextEditingController();
  final _ageController = TextEditingController();
  final _canopyController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scientificNameController.dispose();
    _localNameController.dispose();
    _heightController.dispose();
    _girthController.dispose();
    _ageController.dispose();
    _canopyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SurveyProvider>(
      builder: (context, surveyProvider, child) {
        if (!surveyProvider.isSurveyActive) {
          return _buildStartSurveyView();
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _confirmDiscardSurvey();
            if (shouldPop) {
              if (context.mounted) {
                context.go('/home');
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              title: const Text('Field Survey'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (await _confirmDiscardSurvey()) {
                    context.go('/home');
                  }
                },
                tooltip: 'Back',
              ),
              actions: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: _getSurveyProgress(surveyProvider) / 100,
                        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text('${_getSurveyProgress(surveyProvider).toInt()}%'),
                      const SizedBox(width: 16),
                      // Save draft button
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () => _saveDraft(surveyProvider),
                        tooltip: 'Save Draft',
                      ),
                    ],
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Basic Info'),
                  Tab(text: 'Measurements'),
                  Tab(text: 'Location'),
                  Tab(text: 'Photos'),
                ],
              ),
            ),
            body: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(surveyProvider),
                  _buildMeasurementsTab(surveyProvider),
                  _buildLocationTab(surveyProvider),
                  _buildPhotosTab(surveyProvider),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(
                      alpha: 0.3,
                      red: Colors.grey.r,
                      green: Colors.grey.g,
                      blue: Colors.grey.b,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_tabController.index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _tabController.animateTo(_tabController.index - 1);
                        },
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_tabController.index > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _tabController.index < 3
                          ? () {
                        if (_validateCurrentTab()) {
                          final nextIndex = _tabController.index + 1;
                          if (nextIndex < _tabController.length) {
                            _tabController.animateTo(nextIndex);
                          }
                        }
                      }
                          : surveyProvider.isValidSurvey
                          ? () => _submitSurvey(surveyProvider)
                          : null,
                      child: Text(_tabController.index < 3 ? 'Next' : 'Submit Survey'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartSurveyView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Field Survey'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Ready to Survey Trees?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Start collecting tree data for the census. Make sure you have location permissions enabled.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _startSurvey,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Survey'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(SurveyProvider surveyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tree Identification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _scientificNameController,
            decoration: const InputDecoration(
              labelText: 'Scientific Name *',
              hintText: 'e.g., Quercus alba',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.science),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Scientific name is required';
              }
              return null;
            },
            onChanged: (value) {
              surveyProvider.updateScientificName(value);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _localNameController,
            decoration: const InputDecoration(
              labelText: 'Local/Common Name *',
              hintText: 'e.g., White Oak',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_florist),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Local name is required';
              }
              return null;
            },
            onChanged: (value) {
              surveyProvider.updateLocalName(value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Health Status *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.health_and_safety),
            ),
            value: surveyProvider.healthCondition?.toString().split('.').last,
            items: const [
              DropdownMenuItem(value: 'excellent', child: Text('Excellent')),
              DropdownMenuItem(value: 'good', child: Text('Good')),
              DropdownMenuItem(value: 'fair', child: Text('Fair')),
              DropdownMenuItem(value: 'poor', child: Text('Poor')),
              DropdownMenuItem(value: 'dying', child: Text('Dying')),
              DropdownMenuItem(value: 'dead', child: Text('Dead')),
            ],
            onChanged: (value) {
              if (value != null) {
                // Assuming you have a TreeHealth enum with values matching the strings
                surveyProvider.updateHealthCondition(TreeHealth.values.firstWhere((e) => e.toString().split('.').last == value));
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Health status is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Ownership Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            value: surveyProvider.ownership?.toString().split('.').last,
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'private', child: Text('Private')),
              DropdownMenuItem(value: 'community', child: Text('Community')),
              DropdownMenuItem(value: 'government', child: Text('Government')),
            ],
            onChanged: (value) {
              if (value != null) {
                // If your enum is TreeOwnership, convert string to enum
                surveyProvider.updateOwnership(TreeOwnership.values.firstWhere((e) => e.toString().split('.').last == value));
              }
            },
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Heritage Tree'),
            subtitle: const Text('Mark if this is a heritage or historically significant tree'),
            value: surveyProvider.isHeritage,
            onChanged: (value) {
              surveyProvider.updateHeritage(value ?? false);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Additional observations, condition details, etc.',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_add),
            ),
            maxLines: 3,
            onChanged: (value) {
              // surveyProvider.updateNotes(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTab(SurveyProvider surveyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tree Measurements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All measurements should be taken at standard positions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Height (meters) *',
              hintText: 'e.g., 15.5',
              border: OutlineInputBorder(),
              suffixText: 'm',
              prefixIcon: Icon(Icons.height),
              helperText: 'Total height from ground to top',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Height is required';
              }
              final height = double.tryParse(value);
              if (height == null || height <= 0) {
                return 'Please enter a valid height';
              }
              if (height > 100) {
                return 'Height seems unusually large';
              }
              return null;
            },
            onChanged: (value) {
              final height = double.tryParse(value);
              if (height != null) {
                surveyProvider.updateHeight(height);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _girthController,
            decoration: const InputDecoration(
              labelText: 'Girth/DBH (cm) *',
              hintText: 'e.g., 45.2',
              border: OutlineInputBorder(),
              suffixText: 'cm',
              prefixIcon: Icon(Icons.straighten),
              helperText: 'Diameter at Breast Height (1.3m from ground)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Girth is required';
              }
              final girth = double.tryParse(value);
              if (girth == null || girth <= 0) {
                return 'Please enter a valid girth';
              }
              if (girth > 1000) {
                return 'Girth seems unusually large';
              }
              return null;
            },
            onChanged: (value) {
              final girth = double.tryParse(value);
              if (girth != null) {
                surveyProvider.updateGirth(girth);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Estimated Age (years)',
              hintText: 'e.g., 25',
              border: OutlineInputBorder(),
              suffixText: 'years',
              prefixIcon: Icon(Icons.schedule),
              helperText: 'Best estimate based on size and species',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final age = int.tryParse(value);
              if (age != null) {
                surveyProvider.updateAge(age);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _canopyController,
            decoration: const InputDecoration(
              labelText: 'Canopy Spread (meters)',
              hintText: 'e.g., 8.5',
              border: OutlineInputBorder(),
              suffixText: 'm',
              prefixIcon: Icon(Icons.nature),
              helperText: 'Average diameter of tree crown',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final canopy = double.tryParse(value);
              if (canopy != null) {
                // surveyProvider.updateCanopy(canopy);
              }
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Measurement Tips',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Use a measuring tape for girth at 1.3m height'),
                  const Text('• Estimate height using landmarks or measuring tools'),
                  const Text('• Measure canopy at widest and narrowest points, then average'),
                  const Text('• Age estimation can be based on growth rate for the species'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab(SurveyProvider surveyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (surveyProvider.location != null) ...[
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Location Captured',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Latitude: ${surveyProvider.location!.latitude.toStringAsFixed(6)}'),
                    Text('Longitude: ${surveyProvider.location!.longitude.toStringAsFixed(6)}'),
                    const SizedBox(height: 8),
                    Text('Accuracy: ±${surveyProvider.location!.accuracy.toStringAsFixed(1)}m'),
                    Text('Timestamp: ${DateTime.now().toString().substring(0, 19)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGettingLocation ? null : _getCurrentLocation,
              icon: _isGettingLocation
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.location_on),
              label: Text(_isGettingLocation ? 'Getting Location...' : 'Get Current Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_locationError != null)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            _locationError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Ward/District',
              hintText: 'Administrative area',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map),
            ),
            onChanged: (value) {
              // surveyProvider.updateWard(value);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Address/Landmark',
              hintText: 'Nearby landmark or address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place),
            ),
            maxLines: 2,
            onChanged: (value) {
              // surveyProvider.updateAddress(value);
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Guidelines',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Ensure GPS is enabled on your device'),
                  const Text('• Stand close to the tree for accurate location'),
                  const Text('• Wait for good GPS signal (accuracy < 10m preferred)'),
                  const Text('• Record any nearby landmarks for reference'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosTab(SurveyProvider surveyProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tree Photos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take photos from different angles to document the tree',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          if (surveyProvider.images.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: surveyProvider.images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        surveyProvider.images[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 12,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            _removePhoto(surveyProvider, index);
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _takePhoto(surveyProvider);
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _pickPhoto(surveyProvider);
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo Guidelines',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Take at least 2-3 photos from different angles'),
                  const Text('• Include full tree and close-ups of trunk/bark'),
                  const Text('• Capture any damage, disease, or unique features'),
                  const Text('• Ensure good lighting for clear images'),
                  const Text('• Photos will be compressed to save storage space'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getSurveyProgress(SurveyProvider surveyProvider) {
    int completedFields = 0;
    int totalFields = 8; // Adjust based on required fields

    if (surveyProvider.scientificName?.isNotEmpty == true) completedFields++;
    if (surveyProvider.localName?.isNotEmpty == true) completedFields++;
    if (surveyProvider.height != null) completedFields++;
    if (surveyProvider.girth != null) completedFields++;
    if (surveyProvider.healthCondition != null) completedFields++;
    if (surveyProvider.location != null) completedFields++;
    if (surveyProvider.age != null) completedFields++;
    if (surveyProvider.images.isNotEmpty) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  bool _validateCurrentTab() {
    switch (_tabController.index) {
      case 0: // Basic Info
        return _scientificNameController.text.isNotEmpty &&
            _localNameController.text.isNotEmpty;
      case 1: // Measurements
        return _heightController.text.isNotEmpty &&
            _girthController.text.isNotEmpty &&
            double.tryParse(_heightController.text) != null &&
            double.tryParse(_girthController.text) != null;
      case 2: // Location
        final surveyProvider = Provider.of<SurveyProvider>(context, listen: false);
        return surveyProvider.location != null;
      case 3: // Photos
        return true; // Photos are optional
      default:
        return true;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      final surveyProvider = Provider.of<SurveyProvider>(context, listen: false);
      await surveyProvider.getCurrentLocation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _locationError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _takePhoto(SurveyProvider surveyProvider) async {
    try {
      await surveyProvider.takePhoto();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _pickPhoto(SurveyProvider surveyProvider) async {
    try {
      await surveyProvider.pickImageFromGallery();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking photo: $e')),
      );
    }
  }

  void _removePhoto(SurveyProvider surveyProvider, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              surveyProvider.removeImage(index);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo removed')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _saveDraft(SurveyProvider surveyProvider) {
    try {
      // TODO: Implement draft saving
      // surveyProvider.saveDraft();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving draft: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitSurvey(SurveyProvider surveyProvider) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Survey'),
        content: const Text('Are you sure you want to submit this tree survey? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // TODO: Implement survey submission
      // await surveyProvider.submitSurvey();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text('Survey Submitted'),
              ],
            ),
            content: const Text('Tree survey has been successfully submitted and saved to the database.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetForm();
                },
                child: const Text('Add Another Tree'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/dashboard');
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting survey: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startSurvey() {
    final surveyProvider = Provider.of<SurveyProvider>(context, listen: false);
    surveyProvider.startSurvey();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _scientificNameController.clear();
    _localNameController.clear();
    _heightController.clear();
    _girthController.clear();
    _ageController.clear();
    _canopyController.clear();
    _notesController.clear();
    _tabController.animateTo(0);
    setState(() {
      _locationError = null;
      _isGettingLocation = false;
    });
    // Removed surveyProvider.resetSurvey(); as it does not exist
  }
  Future<bool> _confirmDiscardSurvey() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Survey?'),
        content: const Text('Are you sure you want to go back? Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return shouldPop == true;
  }
}
