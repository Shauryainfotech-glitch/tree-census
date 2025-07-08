import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tree.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class FieldSurveyScreen extends StatefulWidget {
  const FieldSurveyScreen({super.key});

  @override
  State<FieldSurveyScreen> createState() => _FieldSurveyScreenState();
}

class _FieldSurveyScreenState extends State<FieldSurveyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
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
    _checkSurveyStatus();
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

  void _checkSurveyStatus() {
    final surveyProvider = Provider.of<SurveyProvider>(context, listen: false);
    if (!surveyProvider.isSurveyActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStartSurveyDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Survey'),
        actions: [
          Consumer<SurveyProvider>(
            builder: (context, surveyProvider, child) {
              if (surveyProvider.isSurveyActive) {
                return Row(
                  children: [
                    // Progress indicator
                    CircularProgressIndicator(
                      value: surveyProvider.getSurveyProgress() / 100,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text('${surveyProvider.getSurveyProgress()}%'),
                    const SizedBox(width: 16),
                    
                    // Save draft button
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveDraft,
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Measurements'),
            Tab(text: 'Location'),
            Tab(text: 'Photos'),
          ],
        ),
      ),
      body: Consumer<SurveyProvider>(
        builder: (context, surveyProvider, child) {
          if (!surveyProvider.isSurveyActive) {
            return _buildStartSurveyView();
          }

          return Form(
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
          );
        },
      ),
      bottomNavigationBar: Consumer<SurveyProvider>(
        builder: (context, surveyProvider, child) {
          if (!surveyProvider.isSurveyActive) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
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
                              _tabController.animateTo(_tabController.index + 1);
                            }
                          }
                        : surveyProvider.isValidSurvey
                            ? _submitSurvey
                            : null,
                    child: Text(_tabController.index < 3 ? 'Next' : 'Submit Survey'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartSurveyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            Text(
              'Start New Survey',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Begin collecting data for a new tree in the census. Make sure you have GPS enabled and camera access.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startSurvey,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Survey'),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadDraft,
              icon: const Icon(Icons.folder_open),
              label: const Text('Load Draft'),
            ),
          ],
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
          Text(
            'Tree Identification',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Scientific Name
          TextFormField(
            controller: _scientificNameController,
            decoration: const InputDecoration(
              labelText: 'Scientific Name *',
              hintText: 'e.g., Mangifera indica',
              prefixIcon: Icon(Icons.science),
            ),
            validator: surveyProvider.validateScientificName,
            onChanged: surveyProvider.updateScientificName,
          ),
          
          const SizedBox(height: 16),
          
          // Local Name
          TextFormField(
            controller: _localNameController,
            decoration: const InputDecoration(
              labelText: 'Local Name *',
              hintText: 'e.g., Mango',
              prefixIcon: Icon(Icons.local_florist),
            ),
            validator: surveyProvider.validateLocalName,
            onChanged: surveyProvider.updateLocalName,
          ),
          
          const SizedBox(height: 16),
          
          // Health Condition
          DropdownButtonFormField<TreeHealth>(
            value: surveyProvider.healthCondition,
            decoration: const InputDecoration(
              labelText: 'Health Condition *',
              prefixIcon: Icon(Icons.favorite),
            ),
            items: TreeHealth.values.map((health) {
              return DropdownMenuItem(
                value: health,
                child: Text(health.displayName),
              );
            }).toList(),
            onChanged: (health) {
              if (health != null) {
                surveyProvider.updateHealthCondition(health);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Health condition is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Ownership
          DropdownButtonFormField<TreeOwnership>(
            value: surveyProvider.ownership,
            decoration: const InputDecoration(
              labelText: 'Ownership *',
              prefixIcon: Icon(Icons.business),
            ),
            items: TreeOwnership.values.map((ownership) {
              return DropdownMenuItem(
                value: ownership,
                child: Text(ownership.displayName),
              );
            }).toList(),
            onChanged: (ownership) {
              if (ownership != null) {
                surveyProvider.updateOwnership(ownership);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Ownership is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Heritage Tree Checkbox
          CheckboxListTile(
            title: const Text('Heritage Tree'),
            subtitle: const Text('Tree is 50+ years old or has historical significance'),
            value: surveyProvider.isHeritage,
            onChanged: (value) {
              surveyProvider.updateHeritage(value ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          const SizedBox(height: 24),
          
          // AI Assistance Card
          Card(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Assistance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Take a photo of the tree to get AI-powered species identification and health assessment.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _useAIIdentification,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Use AI Identification'),
                    ),
                  ),
                ],
              ),
            ),
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
          Text(
            'Tree Measurements',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Height
          TextFormField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Height (meters) *',
              hintText: 'e.g., 15.5',
              prefixIcon: Icon(Icons.height),
              suffixText: 'm',
            ),
            validator: surveyProvider.validateHeight,
            onChanged: (value) {
              final height = double.tryParse(value);
              if (height != null) {
                surveyProvider.updateHeight(height);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Girth
          TextFormField(
            controller: _girthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Girth (centimeters) *',
              hintText: 'e.g., 120.5',
              prefixIcon: Icon(Icons.straighten),
              suffixText: 'cm',
            ),
            validator: surveyProvider.validateGirth,
            onChanged: (value) {
              final girth = double.tryParse(value);
              if (girth != null) {
                surveyProvider.updateGirth(girth);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Age
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age (years) *',
              hintText: 'e.g., 25',
              prefixIcon: Icon(Icons.calendar_today),
              suffixText: 'years',
            ),
            validator: surveyProvider.validateAge,
            onChanged: (value) {
              final age = int.tryParse(value);
              if (age != null) {
                surveyProvider.updateAge(age);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Canopy Spread
          TextFormField(
            controller: _canopyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Canopy Spread (meters) *',
              hintText: 'e.g., 8.5',
              prefixIcon: Icon(Icons.nature),
              suffixText: 'm',
            ),
            validator: surveyProvider.validateCanopy,
            onChanged: (value) {
              final canopy = double.tryParse(value);
              if (canopy != null) {
                surveyProvider.updateCanopy(canopy);
              }
            },
          ),
          
          const SizedBox(height: 24),
          
          // Measurement Guidelines
          Card(
            color: AppTheme.infoBlue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: AppTheme.infoBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Measurement Guidelines',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.infoBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('• Height: Measure from ground to highest point'),
                  const Text('• Girth: Measure circumference at 1.3m height (DBH)'),
                  const Text('• Age: Estimate based on size and local knowledge'),
                  const Text('• Canopy: Measure average diameter of tree crown'),
                  const SizedBox(height: 12),
                  Text(
                    'Census Criteria: Height ≥ ${AppConstants.minTreeHeight}m, Girth ≥ ${AppConstants.minTreeGirth}cm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          Text(
            'Location Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // GPS Location Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        color: surveyProvider.location != null 
                            ? AppTheme.successGreen 
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GPS Coordinates',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (surveyProvider.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (surveyProvider.location != null) ...[
                    Text(
                      'Coordinates: ${surveyProvider.getFormattedCoordinates()}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accuracy: ${surveyProvider.getLocationAccuracy()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          surveyProvider.isLocationValid() 
                              ? Icons.check_circle 
                              : Icons.warning,
                          size: 16,
                          color: surveyProvider.isLocationValid() 
                              ? AppTheme.successGreen 
                              : AppTheme.warningOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          surveyProvider.isLocationValid() 
                              ? 'Location within Thane city bounds'
                              : 'Warning: Location outside Thane city',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: surveyProvider.isLocationValid() 
                                ? AppTheme.successGreen 
                                : AppTheme.warningOrange,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text('GPS location not available'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: surveyProvider.getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Current Location'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ward Selection
          DropdownButtonFormField<String>(
            value: surveyProvider.ward,
            decoration: const InputDecoration(
              labelText: 'Ward *',
              prefixIcon: Icon(Icons.location_city),
            ),
            items: AppConstants.thaneWards.map((ward) {
              return DropdownMenuItem(
                value: ward,
                child: Text(ward),
              );
            }).toList(),
            onChanged: (ward) {
              if (ward != null) {
                surveyProvider.updateWard(ward);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ward is required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Location Tips
          Card(
            color: AppTheme.warningOrange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: AppTheme.warningOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location Tips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('• Ensure GPS is enabled on your device'),
                  const Text('• Stand close to the tree for accurate coordinates'),
                  const Text('• Wait for GPS accuracy to improve (< 10m)'),
                  const Text('• Ward will be auto-detected from GPS location'),
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
          Text(
            'Tree Photos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Photo Grid
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
                final image = surveyProvider.images[index];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed: () => surveyProvider.removeImage(index),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Photo Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: surveyProvider.takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: surveyProvider.pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('From Gallery'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Notes Section
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            maxLength: AppConstants.maxNotesLength,
            decoration: const InputDecoration(
              labelText: 'Additional Notes',
              hintText: 'Any additional observations about the tree...',
              prefixIcon: Icon(Icons.note),
              alignLabelWithHint: true,
            ),
            onChanged: surveyProvider.updateNotes,
          ),
          
          const SizedBox(height: 24),
          
          // Photo Guidelines
          Card(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_camera,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Photo Guidelines',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('• Take photos from multiple angles'),
                  const Text('• Include full tree and close-up of trunk'),
                  const Text('• Capture any diseases or damage'),
                  const Text('• Ensure good lighting for AI analysis'),
                  Text('• Maximum ${AppConstants.maxImagesPerTree} photos per tree'),
                ],
              ),
            ),
          ),
          
          if (surveyProvider.errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppTheme.errorRed.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        surveyProvider.errorMessage!,
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _validateCurrentTab() {
    switch (_tabController.index) {
      case 0: // Basic Info
        return _scientificNameController.text.isNotEmpty &&
               _localNameController.text.isNotEmpty;
      case 1: // Measurements
        return _heightController.text.isNotEmpty &&
               _girthController.text.isNotEmpty &&
               _ageController.text.isNotEmpty &&
               _canopyController.text.isNotEmpty;
      case 2: // Location
        final surveyProvider = Provider.of<SurveyProvider>(context, listen: false);
        return surveyProvider.location != null && surveyProvider.ward != null;
      case 3: // Photos
        return true; // Photos are optional
      default:
        return true;
    }
  }

  void _showStartSurveyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Start New Survey'),
        content: const Text(
          'This will start a new tree survey. Make sure you have:\n\n'
          '• GPS enabled\n'
          '• Camera access\n'
          '• Good network connection\n\n'
          'You can save drafts and continue later.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startSurvey();
            },
            child: const Text('Start Survey'),
          ),
        ],
      ),
    );
  }

  Future<void> _startSurvey() async {
    final surveyProvider = Provider.of<SurveyProvider>(context, listen: false);
    await surveyProvider.startSurvey();
  }

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final surveyProvider = Provider.of<SurveyProvider>(context, listen: false);
    
    final success = await surveyProvider.submitSurvey(authProvider.currentUser!.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Survey submitted successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _saveDraft() async {
    final surveyProvider = Provider.of<SurveyProvider>(context, listen: false);
    final success = await surveyProvider.saveDraft();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadDraft() {
    // TODO: Implement draft loading functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft loading feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _useAIIdentification() {
    // TODO: Implement AI identification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI identification feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
