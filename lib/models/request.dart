enum RequestStatus {
  pending,
  approved,
  rejected,
  inProgress,
  completed,
  cancelled,
}

extension RequestStatusExtension on RequestStatus {
  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
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
}

enum RequestType {
  removal,
  trimming,
  plantation,
  survey,
}

extension RequestTypeExtension on RequestType {
  String get displayName {
    switch (this) {
      case RequestType.removal:
        return 'Removal';
      case RequestType.trimming:
        return 'Trimming';
      case RequestType.plantation:
        return 'Plantation';
      case RequestType.survey:
        return 'Survey';
    }
  }
}

