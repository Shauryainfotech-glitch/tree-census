// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tree_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreeRequestAdapter extends TypeAdapter<TreeRequest> {
  @override
  final int typeId = 5;

  @override
  TreeRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TreeRequest(
      id: fields[0] as String,
      applicantName: fields[1] as String,
      mobile: fields[2] as String,
      aadhar: fields[3] as String,
      requestType: fields[4] as RequestType,
      treeId: fields[5] as String?,
      reason: fields[6] as String,
      status: fields[7] as RequestStatus,
      submissionDate: fields[8] as DateTime,
      documents: (fields[9] as List?)?.cast<String>(),
      inspectionReport: fields[10] as String?,
      fee: fields[11] as double?,
      paymentStatus: fields[12] as PaymentStatus?,
      adminComments: fields[13] as String?,
      approvalDate: fields[14] as DateTime?,
      approvedBy: fields[15] as String?,
      applicantEmail: fields[16] as String,
      address: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TreeRequest obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.applicantName)
      ..writeByte(2)
      ..write(obj.mobile)
      ..writeByte(3)
      ..write(obj.aadhar)
      ..writeByte(4)
      ..write(obj.requestType)
      ..writeByte(5)
      ..write(obj.treeId)
      ..writeByte(6)
      ..write(obj.reason)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.submissionDate)
      ..writeByte(9)
      ..write(obj.documents)
      ..writeByte(10)
      ..write(obj.inspectionReport)
      ..writeByte(11)
      ..write(obj.fee)
      ..writeByte(12)
      ..write(obj.paymentStatus)
      ..writeByte(13)
      ..write(obj.adminComments)
      ..writeByte(14)
      ..write(obj.approvalDate)
      ..writeByte(15)
      ..write(obj.approvedBy)
      ..writeByte(16)
      ..write(obj.applicantEmail)
      ..writeByte(17)
      ..write(obj.address);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RequestTypeAdapter extends TypeAdapter<RequestType> {
  @override
  final int typeId = 6;

  @override
  RequestType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RequestType.pruning;
      case 1:
        return RequestType.cutting;
      case 2:
        return RequestType.transplanting;
      case 3:
        return RequestType.treatment;
      default:
        return RequestType.pruning;
    }
  }

  @override
  void write(BinaryWriter writer, RequestType obj) {
    switch (obj) {
      case RequestType.pruning:
        writer.writeByte(0);
        break;
      case RequestType.cutting:
        writer.writeByte(1);
        break;
      case RequestType.transplanting:
        writer.writeByte(2);
        break;
      case RequestType.treatment:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RequestStatusAdapter extends TypeAdapter<RequestStatus> {
  @override
  final int typeId = 7;

  @override
  RequestStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RequestStatus.pending;
      case 1:
        return RequestStatus.approved;
      case 2:
        return RequestStatus.rejected;
      case 3:
        return RequestStatus.inProgress;
      case 4:
        return RequestStatus.completed;
      case 5:
        return RequestStatus.cancelled;
      default:
        return RequestStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, RequestStatus obj) {
    switch (obj) {
      case RequestStatus.pending:
        writer.writeByte(0);
        break;
      case RequestStatus.approved:
        writer.writeByte(1);
        break;
      case RequestStatus.rejected:
        writer.writeByte(2);
        break;
      case RequestStatus.inProgress:
        writer.writeByte(3);
        break;
      case RequestStatus.completed:
        writer.writeByte(4);
        break;
      case RequestStatus.cancelled:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentStatusAdapter extends TypeAdapter<PaymentStatus> {
  @override
  final int typeId = 8;

  @override
  PaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentStatus.pending;
      case 1:
        return PaymentStatus.paid;
      case 2:
        return PaymentStatus.failed;
      case 3:
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentStatus obj) {
    switch (obj) {
      case PaymentStatus.pending:
        writer.writeByte(0);
        break;
      case PaymentStatus.paid:
        writer.writeByte(1);
        break;
      case PaymentStatus.failed:
        writer.writeByte(2);
        break;
      case PaymentStatus.refunded:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
