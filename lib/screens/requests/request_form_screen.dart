import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/tree_request.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _applicantNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadharController = TextEditingController();
  final _addressController = TextEditingController();
  final _reasonController = TextEditingController();
  final _treeIdController = TextEditingController();
  
  RequestType _selectedRequestType = RequestType.pruning;
  double _estimatedFee = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateEstimatedFee();
    _loadUserData();
  }

  @override
  void dispose() {
    _applicantNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _aadharController.dispose();
    _addressController.dispose();
    _reasonController.dispose();
    _treeIdController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _applicantNameController.text = user.name;
      _emailController.text = user.email;
      _mobileController.text = user.mobile;
    }
  }

  void _calculateEstimatedFee() {
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    setState(() {
      _estimatedFee = requestProvider.calculateEstimatedFee(_selectedRequestType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
          title: const Text('Request Form'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request Type Section
                _buildRequestTypeSection(),

                const SizedBox(height: 24),

                // Applicant Information
                _buildApplicantInfoSection(),

                const SizedBox(height: 24),

                // Tree Information
                _buildTreeInfoSection(),

                const SizedBox(height: 24),

                // Request Details
                _buildRequestDetailsSection(),

                const SizedBox(height: 24),

                // Fee Information
                _buildFeeInfoSection(),

                const SizedBox(height: 24),

                // Terms and Conditions
                _buildTermsSection(),

                const SizedBox(height: 32),

                // Submit Button
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...RequestType.values.map((type) {
              return RadioListTile<RequestType>(
                title: Text(type.displayName),
                subtitle: Text(type.description),
                value: type,
                groupValue: _selectedRequestType,
                onChanged: (value) {
                  setState(() {
                    _selectedRequestType = value!;
                    _calculateEstimatedFee();
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applicant Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Full Name
            TextFormField(
              controller: _applicantNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.requiredField;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Mobile Number
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                prefixIcon: Icon(Icons.phone),
                prefixText: '+91 ',
              ),
              maxLength: 10,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.requiredField;
                }
                if (value.length != 10) {
                  return AppConstants.invalidMobile;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.requiredField;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return AppConstants.invalidEmail;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Aadhar Number
            TextFormField(
              controller: _aadharController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Aadhar Number *',
                prefixIcon: Icon(Icons.credit_card),
                hintText: 'XXXX XXXX XXXX',
              ),
              maxLength: 12,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.requiredField;
                }
                if (value.length != 12) {
                  return AppConstants.invalidAadhar;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address *',
                prefixIcon: Icon(Icons.location_on),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.requiredField;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tree Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tree ID (optional)
            TextFormField(
              controller: _treeIdController,
              decoration: const InputDecoration(
                labelText: 'Tree ID (if known)',
                prefixIcon: Icon(Icons.qr_code),
                hintText: 'e.g., TMC001',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tree Search Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _searchTree,
                icon: const Icon(Icons.search),
                label: const Text('Search Tree by Location'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Help Text
            Text(
              'If you don\'t know the Tree ID, you can search for trees near your location or provide detailed location information in the reason field.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Reason
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason for Request *',
                hintText: 'Please provide detailed reason for the request including tree location, safety concerns, etc.',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.requiredField;
                }
                if (value.length < 20) {
                  return 'Please provide a detailed reason (minimum 20 characters)';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Guidelines
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.infoBlue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: AppTheme.infoBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Guidelines',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.infoBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Provide exact location of the tree\n'
                    '• Mention safety concerns if any\n'
                    '• Include photos if possible\n'
                    '• Specify urgency level\n'
                    '• Mention any previous complaints',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Fee:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '₹${_estimatedFee.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Note: Final fee may vary based on tree size, location, and complexity of work. Payment will be required after approval.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Fee Breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee Structure:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...RequestType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type.displayName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '₹${type.baseFee.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              '• Request will be reviewed by TMC authorities\n'
              '• Site inspection may be conducted\n'
              '• Approval is subject to ${AppConstants.legalAct}\n'
              '• Work will be carried out by authorized personnel only\n'
              '• Payment is required before work commencement\n'
              '• Processing time: 7-15 working days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            
            const SizedBox(height: 16),
            
            CheckboxListTile(
              title: const Text('I agree to the terms and conditions'),
              subtitle: const Text('I understand that providing false information may result in rejection'),
              value: _termsAccepted,
              onChanged: (value) {
                setState(() {
                  _termsAccepted = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  bool _termsAccepted = false;

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.send),
        label: const Text('Submit Request'),
        onPressed: () async {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          if (!_termsAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please accept the terms and conditions'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
            return;
          }
          final requestProvider = Provider.of<RequestProvider>(context, listen: false);
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final user = authProvider.currentUser;
          final newRequest = TreeRequest(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            applicantName: _applicantNameController.text,
            mobile: _mobileController.text,
            aadhar: _aadharController.text,
            requestType: _selectedRequestType,
            treeId: _treeIdController.text.isNotEmpty ? _treeIdController.text : null,
            reason: _reasonController.text,
            status: RequestStatus.pending,
            submissionDate: DateTime.now(),
            documents: [],
            inspectionReport: null,
            fee: _estimatedFee,
            paymentStatus: PaymentStatus.pending,
            adminComments: null,
            approvalDate: null,
            approvedBy: null,
            applicantEmail: _emailController.text,
            address: _addressController.text,
          );
          await requestProvider.submitRequest(newRequest);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Request submitted successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    
    final request = TreeRequest(
      id: 'REQ_${DateTime.now().millisecondsSinceEpoch}',
      applicantName: _applicantNameController.text.trim(),
      mobile: _mobileController.text.trim(),
      aadhar: _aadharController.text.trim(),
      requestType: _selectedRequestType,
      treeId: _treeIdController.text.trim().isNotEmpty 
          ? _treeIdController.text.trim() 
          : null,
      reason: _reasonController.text.trim(),
      status: RequestStatus.pending,
      submissionDate: DateTime.now(),
      applicantEmail: _emailController.text.trim(),
      address: _addressController.text.trim(),
      fee: _estimatedFee,
      paymentStatus: PaymentStatus.pending,
    );

    final success = await requestProvider.submitRequest(request);

    if (success && mounted) {
      _showSuccessDialog(request.id);
    } else if (mounted && requestProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(requestProvider.errorMessage!),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showSuccessDialog(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: AppTheme.successGreen,
          size: 48,
        ),
        title: const Text('Request Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your request has been submitted successfully.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Request ID',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    requestId,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You will receive updates via SMS and email. Processing time is 7-15 working days.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('View Requests'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _searchTree() {
    // TODO: Navigate to tree search screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tree search feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to submit a request:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Select the type of service needed'),
              Text('2. Fill in your personal information'),
              Text('3. Provide tree location or ID'),
              Text('4. Explain the reason for request'),
              Text('5. Review fee information'),
              Text('6. Accept terms and submit'),
              SizedBox(height: 16),
              Text(
                'Need help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Call: ${AppConstants.supportPhone}'),
              Text('Email: ${AppConstants.supportEmail}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
