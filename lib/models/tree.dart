import 'package:hive/hive.dart';

part 'tree.g.dart';

@HiveType(typeId: 0)
class Tree extends HiveObject {
  @HiveField(0)
  String id;

  String get imageUrl => images?.isNotEmpty == true ? images!.first : '';
  String get scientificName => species;
  String get area => ward;
  String get street => notes ?? '';
  double get latitude => lat;
  double get longitude => lng;
  String get condition => health.displayName;
  String? get healthIssues => health != TreeHealth.healthy ? health.description : null;
  DateTime? get lastInspectionDate => lastSurveyDate;
  String? get surveyedBy => surveyorId;
  DateTime? get surveyDate => lastSurveyDate;

  @HiveField(1)
  String species;

  @HiveField(2)
  String localName;

  @HiveField(3)
  double lat;

  @HiveField(4)
  double lng;

  @HiveField(5)
  double height;

  @HiveField(6)
  double girth;

  @HiveField(7)
  int age;

  @HiveField(8)
  bool heritage;

  @HiveField(9)
  String ward;

  @HiveField(10)
  TreeHealth health;

  @HiveField(11)
  double canopy;

  @HiveField(12)
  TreeOwnership ownership;

  @HiveField(13)
  List<String>? images;

  @HiveField(14)
  DateTime? lastSurveyDate;

  @HiveField(15)
  String? surveyorId;

  @HiveField(16)
  String? notes;

  Tree({
    required this.id,
    required this.species,
    required this.localName,
    required this.lat,
    required this.lng,
    required this.height,
    required this.girth,
    required this.age,
    required this.heritage,
    required this.ward,
    required this.health,
    required this.canopy,
    required this.ownership,
    this.images,
    this.lastSurveyDate,
    this.surveyorId,
    this.notes,
  });

  factory Tree.fromJson(Map<String, dynamic> json) {
    return Tree(
      id: json['id'],
      species: json['species'],
      localName: json['localName'],
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
      height: json['height'].toDouble(),
      girth: json['girth'].toDouble(),
      age: json['age'],
      heritage: json['heritage'],
      ward: json['ward'],
      health: TreeHealth.values.firstWhere(
        (e) => e.toString().split('.').last == json['health'],
        orElse: () => TreeHealth.healthy,
      ),
      canopy: json['canopy'].toDouble(),
      ownership: TreeOwnership.values.firstWhere(
        (e) => e.toString().split('.').last == json['ownership'],
        orElse: () => TreeOwnership.government,
      ),
      images: json['images']?.cast<String>(),
      lastSurveyDate: json['lastSurveyDate'] != null 
          ? DateTime.parse(json['lastSurveyDate']) 
          : null,
      surveyorId: json['surveyorId'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'species': species,
      'localName': localName,
      'lat': lat,
      'lng': lng,
      'height': height,
      'girth': girth,
      'age': age,
      'heritage': heritage,
      'ward': ward,
      'health': health.toString().split('.').last,
      'canopy': canopy,
      'ownership': ownership.toString().split('.').last,
      'images': images,
      'lastSurveyDate': lastSurveyDate?.toIso8601String(),
      'surveyorId': surveyorId,
      'notes': notes,
    };
  }
}

@HiveType(typeId: 1)
enum TreeHealth {
  @HiveField(0)
  healthy,
  @HiveField(1)
  diseased,
  @HiveField(2)
  mechanicallyDamaged,
  @HiveField(3)
  poor,
  @HiveField(4)
  uprooted,
}

@HiveType(typeId: 2)
enum TreeOwnership {
  @HiveField(0)
  government,
  @HiveField(1)
  private,
  @HiveField(2)
  garden,
  @HiveField(3)
  roadDivider,
}

extension TreeHealthExtension on TreeHealth {
  String get displayName {
    switch (this) {
      case TreeHealth.healthy:
        return 'Healthy';
      case TreeHealth.diseased:
        return 'Diseased';
      case TreeHealth.mechanicallyDamaged:
        return 'Mechanically Damaged';
      case TreeHealth.poor:
        return 'Poor';
      case TreeHealth.uprooted:
        return 'Uprooted';
    }
  }

  String get description {
    switch (this) {
      case TreeHealth.healthy:
        return 'Tree is in good condition with no visible issues';
      case TreeHealth.diseased:
        return 'Tree shows signs of disease or pest infestation';
      case TreeHealth.mechanicallyDamaged:
        return 'Tree has physical damage from external factors';
      case TreeHealth.poor:
        return 'Tree is in declining health condition';
      case TreeHealth.uprooted:
        return 'Tree has been uprooted or fallen';
    }
  }
}

extension TreeOwnershipExtension on TreeOwnership {
  String get displayName {
    switch (this) {
      case TreeOwnership.government:
        return 'Government';
      case TreeOwnership.private:
        return 'Private';
      case TreeOwnership.garden:
        return 'Garden';
      case TreeOwnership.roadDivider:
        return 'Road Divider';
    }
  }
}