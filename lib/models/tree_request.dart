import 'package:hive/hive.dart';

part 'tree_request.g.dart';

@HiveType(typeId: 5)
class TreeRequest extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String applicantName;

  @HiveField(2)
  String mobile;

  @HiveField(3)
  String aadhar;

  @HiveField(4)
  RequestType requestType;

  @HiveField(5)
  String? treeId;

  @HiveField(6)
  String reason;

  @HiveField(7)
  RequestStatus status;

  @HiveField(8)
  DateTime submissionDate;

  @HiveField(9)
  List<String>? documents;

  @HiveField(10)
  String? inspectionReport;

  @HiveField(11)
  double? fee;

  @HiveField(12)
  PaymentStatus? paymentStatus;

  @HiveField(13)
  String? adminComments;

  @HiveField(14)
  DateTime? approvalDate;

  @HiveField(15)
  String? approvedBy;

  @HiveField(16)
  String applicantEmail;

  @HiveField(17)
  String address;

  TreeRequest({
    required this.id,
    required this.applicantName,
    required this.mobile,
    required this.aadhar,
    required this.requestType,
    this.treeId,
    required this.reason,
    required this.status,
    required this.submissionDate,
    this.documents,
    this.inspectionReport,
    this.fee,
    this.paymentStatus,
    this.adminComments,
    this.approvalDate,
    this.approvedBy,
    required this.applicantEmail,
    required this.address,
  });

  factory TreeRequest.fromJson(Map<String, dynamic> json) {
    return TreeRequest(
      id: json['id'],
      applicantName: json['applicantName'],
      mobile: json['mobile'],
      aadhar: json['aadhar'],
      requestType: RequestType.values.firstWhere(
        (e) => e.toString().split('.').last == json['requestType'],
        orElse: () => RequestType.pruning,
      ),
      treeId: json['treeId'],
      reason: json['reason'],
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      submissionDate: DateTime.parse(json['submissionDate']),
      documents: json['documents']?.cast<String>(),
      inspectionReport: json['inspectionReport'],
      fee: json['fee']?.toDouble(),
      paymentStatus: json['paymentStatus'] != null
          ? PaymentStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['paymentStatus'],
              orElse: () => PaymentStatus.pending,
            )
          : null,
      adminComments: json['adminComments'],
      approvalDate: json['approvalDate'] != null 
          ? DateTime.parse(json['approvalDate']) 
          : null,
      approvedBy: json['approvedBy'],
      applicantEmail: json['applicantEmail'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicantName': applicantName,
      'mobile': mobile,
      'aadhar': aadhar,
      'requestType': requestType.toString().split('.').last,
      'treeId': treeId,
      'reason': reason,
      'status': status.toString().split('.').last,
      'submissionDate': submissionDate.toIso8601String(),
      'documents': documents,
      'inspectionReport': inspectionReport,
      'fee': fee,
      'paymentStatus': paymentStatus?.toString().split('.').last,
      'adminComments': adminComments,
      'approvalDate': approvalDate?.toIso8601String(),
      'approvedBy': approvedBy,
      'applicantEmail': applicantEmail,
      'address': address,
    };
  }
}

@HiveType(typeId: 6)
enum RequestType {
  @HiveField(0)
  pruning,
  @HiveField(1)
  cutting,
  @HiveField(2)
  transplanting,
  @HiveField(3)
  treatment,
}

@HiveType(typeId: 7)
enum RequestStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  approved,
  @HiveField(2)
  rejected,
  @HiveField(3)
  inProgress,
  @HiveField(4)
  completed,
  @HiveField(5)
  cancelled,
}

@HiveType(typeId: 8)
enum PaymentStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  paid,
  @HiveField(2)
  failed,
  @HiveField(3)
  refunded,
}

extension RequestTypeExtension on RequestType {
  String get displayName {
    switch (this) {
      case RequestType.pruning:
        return 'Tree Pruning';
      case RequestType.cutting:
        return 'Tree Cutting';
      case RequestType.transplanting:
        return 'Tree Transplanting';
      case RequestType.treatment:
        return 'Tree Treatment';
    }
  }

  String get description {
    switch (this) {
      case RequestType.pruning:
        return 'Request for trimming or pruning tree branches';
      case RequestType.cutting:
        return 'Request for complete tree removal';
      case RequestType.transplanting:
        return 'Request for relocating a tree';
      case RequestType.treatment:
        return 'Request for tree health treatment';
    }
  }

  double get baseFee {
    switch (this) {
      case RequestType.pruning:
        return 500.0;
      case RequestType.cutting:
        return 2000.0;
      case RequestType.transplanting:
        return 5000.0;
      case RequestType.treatment:
        return 1000.0;
    }
  }
}

extension RequestStatusExtension on RequestStatus {
  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending Review';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case RequestStatus.pending:
        return 'Request is under review by authorities';
      case RequestStatus.approved:
        return 'Request has been approved and can proceed';
      case RequestStatus.rejected:
        return 'Request has been rejected';
      case RequestStatus.inProgress:
        return 'Work is currently in progress';
      case RequestStatus.completed:
        return 'Request has been completed successfully';
      case RequestStatus.cancelled:
        return 'Request has been cancelled';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.paid:
        return 'Payment Completed';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Payment Refunded';
    }
  }
}
