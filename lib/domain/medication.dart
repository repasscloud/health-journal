import 'regimen.dart';

enum AdministrationStatus { taken, skipped, missed, unknown }

/// Product strength and administered amount are deliberately separate.
final class Medication {
  Medication({
    required this.id,
    required String name,
    required this.strength,
    required this.createdAt,
    this.archived = false,
    this.genericName = '',
    this.brand = '',
    this.form = '',
    this.strengthUnit = '',
    this.instructions = '',
    this.reason = '',
    this.prescribedBy = '',
    this.notes = '',
    this.startedAt,
    this.stoppedAt,
    this.pausedAt,
    DateTime? updatedAt,
  }) : name = name.trim(),
       updatedAt = updatedAt ?? createdAt {
    if (id.isEmpty || this.name.isEmpty) {
      throw ArgumentError('A medication needs an ID and name.');
    }
    if ([
          createdAt,
          this.updatedAt,
          startedAt,
          stoppedAt,
          pausedAt,
        ].whereType<DateTime>().any((d) => !d.isUtc) ||
        this.updatedAt.isBefore(createdAt)) {
      throw ArgumentError('Use ordered UTC timestamps.');
    }
    if (startedAt != null &&
        [
          stoppedAt,
          pausedAt,
        ].whereType<DateTime>().any((d) => d.isBefore(startedAt!))) {
      throw ArgumentError('Stop/pause cannot precede start.');
    }
  }
  final String id;
  final String name;
  final String strength;
  final DateTime createdAt;
  final bool archived;
  final String genericName,
      brand,
      form,
      strengthUnit,
      instructions,
      reason,
      prescribedBy,
      notes;
  final DateTime updatedAt;
  final DateTime? startedAt, stoppedAt, pausedAt;
}

final class Administration {
  Administration({
    required this.id,
    required this.medicationId,
    required this.medicationNameSnapshot,
    required this.status,
    required this.recordedAt,
    required this.amount,
    required this.unit,
    this.takenAt,
    this.regimenId,
    this.regimenSnapshot,
    this.medicationSnapshot,
    DateTime? occurredAt,
    this.notes = '',
    this.correctsId,
    this.correctionReason = '',
  }) : occurredAt = occurredAt ?? takenAt ?? recordedAt {
    if (id.trim().isEmpty ||
        medicationId.trim().isEmpty ||
        medicationNameSnapshot.trim().isEmpty) {
      throw ArgumentError(
        'An administration needs stable IDs and a medication snapshot.',
      );
    }
    if (!amount.isFinite || amount <= 0 || unit.trim().isEmpty) {
      throw ArgumentError('Enter a positive amount and unit.');
    }
    if ((status == AdministrationStatus.taken) != (takenAt != null)) {
      throw ArgumentError('Only confirmed intake has a taken time.');
    }
    if (!this.occurredAt.isUtc ||
        this.occurredAt.isAfter(recordedAt) ||
        (takenAt != null && takenAt != this.occurredAt) ||
        (correctsId != null &&
            (correctsId == id || correctionReason.trim().isEmpty))) {
      throw ArgumentError('Invalid event time or correction.');
    }
    if (!recordedAt.isUtc || (takenAt != null && !takenAt!.isUtc)) {
      throw ArgumentError('Use UTC timestamps.');
    }
  }
  final String id;
  final String medicationId;
  final String medicationNameSnapshot;
  final AdministrationStatus status;
  final DateTime recordedAt;
  final DateTime? takenAt;
  final String? regimenId;
  final Regimen? regimenSnapshot;
  final Medication? medicationSnapshot;
  final DateTime occurredAt;
  final String notes, correctionReason;
  final String? correctsId;
  final double amount;
  final String unit;
}
