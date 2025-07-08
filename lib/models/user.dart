import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 3)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String mobile;

  @HiveField(4)
  UserRole role;

  @HiveField(5)
  List<String>? assignedWards;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  DateTime? lastLogin;

  @HiveField(8)
  String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    this.assignedWards,
    required this.isActive,
    this.lastLogin,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.citizen,
      ),
      assignedWards: json['assignedWards']?.cast<String>(),
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role.toString().split('.').last,
      'assignedWards': assignedWards,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'profileImage': profileImage,
    };
  }
}

@HiveType(typeId: 4)
enum UserRole {
  @HiveField(0)
  admin,
  @HiveField(1)
  surveyor,
  @HiveField(2)
  citizen,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.surveyor:
        return 'Field Surveyor';
      case UserRole.citizen:
        return 'Citizen';
    }
  }

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Full system access and management capabilities';
      case UserRole.surveyor:
        return 'Field data collection and tree survey access';
      case UserRole.citizen:
        return 'Tree search and request submission access';
    }
  }

  List<String> get permissions {
    switch (this) {
      case UserRole.admin:
        return [
          'view_dashboard',
          'manage_users',
          'approve_requests',
          'view_all_trees',
          'export_data',
          'system_settings',
        ];
      case UserRole.surveyor:
        return [
          'conduct_surveys',
          'add_trees',
          'edit_trees',
          'view_assigned_areas',
          'upload_images',
        ];
      case UserRole.citizen:
        return [
          'search_trees',
          'submit_requests',
          'view_own_requests',
          'basic_tree_info',
        ];
    }
  }
}
