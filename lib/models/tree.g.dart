// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tree.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreeAdapter extends TypeAdapter<Tree> {
  @override
  final int typeId = 0;

  @override
  Tree read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tree(
      id: fields[0] as String,
      species: fields[1] as String,
      localName: fields[2] as String,
      lat: fields[3] as double,
      lng: fields[4] as double,
      height: fields[5] as double,
      girth: fields[6] as double,
      age: fields[7] as int,
      heritage: fields[8] as bool,
      ward: fields[9] as String,
      health: fields[10] as TreeHealth,
      canopy: fields[11] as double,
      ownership: fields[12] as TreeOwnership,
      images: (fields[13] as List?)?.cast<String>(),
      lastSurveyDate: fields[14] as DateTime?,
      surveyorId: fields[15] as String?,
      notes: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Tree obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.species)
      ..writeByte(2)
      ..write(obj.localName)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.lng)
      ..writeByte(5)
      ..write(obj.height)
      ..writeByte(6)
      ..write(obj.girth)
      ..writeByte(7)
      ..write(obj.age)
      ..writeByte(8)
      ..write(obj.heritage)
      ..writeByte(9)
      ..write(obj.ward)
      ..writeByte(10)
      ..write(obj.health)
      ..writeByte(11)
      ..write(obj.canopy)
      ..writeByte(12)
      ..write(obj.ownership)
      ..writeByte(13)
      ..write(obj.images)
      ..writeByte(14)
      ..write(obj.lastSurveyDate)
      ..writeByte(15)
      ..write(obj.surveyorId)
      ..writeByte(16)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TreeHealthAdapter extends TypeAdapter<TreeHealth> {
  @override
  final int typeId = 1;

  @override
  TreeHealth read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TreeHealth.healthy;
      case 1:
        return TreeHealth.diseased;
      case 2:
        return TreeHealth.mechanicallyDamaged;
      case 3:
        return TreeHealth.poor;
      case 4:
        return TreeHealth.uprooted;
      default:
        return TreeHealth.healthy;
    }
  }

  @override
  void write(BinaryWriter writer, TreeHealth obj) {
    switch (obj) {
      case TreeHealth.healthy:
        writer.writeByte(0);
        break;
      case TreeHealth.diseased:
        writer.writeByte(1);
        break;
      case TreeHealth.mechanicallyDamaged:
        writer.writeByte(2);
        break;
      case TreeHealth.poor:
        writer.writeByte(3);
        break;
      case TreeHealth.uprooted:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeHealthAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TreeOwnershipAdapter extends TypeAdapter<TreeOwnership> {
  @override
  final int typeId = 2;

  @override
  TreeOwnership read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TreeOwnership.government;
      case 1:
        return TreeOwnership.private;
      case 2:
        return TreeOwnership.garden;
      case 3:
        return TreeOwnership.roadDivider;
      default:
        return TreeOwnership.government;
    }
  }

  @override
  void write(BinaryWriter writer, TreeOwnership obj) {
    switch (obj) {
      case TreeOwnership.government:
        writer.writeByte(0);
        break;
      case TreeOwnership.private:
        writer.writeByte(1);
        break;
      case TreeOwnership.garden:
        writer.writeByte(2);
        break;
      case TreeOwnership.roadDivider:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeOwnershipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
