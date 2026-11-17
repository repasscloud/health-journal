enum AdministrationStatus { taken, skipped, missed, unknown }

/// Product strength and administered amount are deliberately separate.
final class Medication {
  Medication({
    required this.id,
    required String name,
    required this.strength,
    required this.createdAt,
    this.archived = false,
  }) : name = name.trim() {
    if (id.isEmpty || this.name.isEmpty) {
      throw ArgumentError('A medication needs an ID and name.');
    }
    if (!createdAt.isUtc) throw ArgumentError('Use UTC timestamps.');
  }
  final String id;
  final String name;
  final String strength;
  final DateTime createdAt;
  final bool archived;
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
  }) {
    if (!amount.isFinite || amount <= 0 || unit.trim().isEmpty) {
      throw ArgumentError('Enter a positive amount and unit.');
    }
    if ((status == AdministrationStatus.taken) != (takenAt != null)) {
      throw ArgumentError('Only confirmed intake has a taken time.');
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
  final double amount;
  final String unit;
}
