import 'medication.dart';

enum ScheduleKind { fixed, course, prn }

/// Local wall-clock rule. Device-local policy is explicit; no UTC clock guessing.
final class ScheduleRule {
  ScheduleRule({
    required this.hour,
    required this.minute,
    required Set<int> weekdays,
  }) : weekdays = Set.unmodifiable(weekdays) {
    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        weekdays.isEmpty ||
        weekdays.any((d) => d < 1 || d > 7)) {
      throw ArgumentError('Choose a valid local time and weekdays.');
    }
  }
  final int hour;
  final int minute;
  final Set<int> weekdays;
  String get localTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Revisions are immutable. A new regimen never rewrites an administration.
final class Regimen {
  Regimen({
    required this.id,
    required this.medicationId,
    required this.amount,
    required String unit,
    required this.kind,
    required this.effectiveFrom,
    this.effectiveTo,
    this.instructions = '',
    this.reminderEnabled = false,
    List<ScheduleRule> rules = const [],
  }) : unit = unit.trim(),
       rules = List.unmodifiable(rules) {
    if (id.isEmpty ||
        medicationId.isEmpty ||
        !amount.isFinite ||
        amount <= 0 ||
        this.unit.isEmpty ||
        !effectiveFrom.isUtc ||
        (effectiveTo != null &&
            (!effectiveTo!.isUtc || !effectiveTo!.isAfter(effectiveFrom)))) {
      throw ArgumentError(
        'Enter a positive dose, unit and valid UTC effective dates.',
      );
    }
    if ((kind == ScheduleKind.prn) != rules.isEmpty ||
        (kind == ScheduleKind.course && effectiveTo == null)) {
      throw ArgumentError(
        'PRN has no due times; fixed/course require times and courses an end.',
      );
    }
    for (var i = 0; i < rules.length; i++) {
      for (var j = i + 1; j < rules.length; j++) {
        if (rules[i].localTime == rules[j].localTime &&
            rules[i].weekdays.intersection(rules[j].weekdays).isNotEmpty) {
          throw ArgumentError(
            'Schedule rules cannot repeat the same weekday/time.',
          );
        }
      }
    }
  }
  final String id;
  final String medicationId;
  final double amount;
  final String unit;
  final ScheduleKind kind;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String instructions;
  final bool reminderEnabled;
  final List<ScheduleRule> rules;
  String get zonePolicy => 'deviceLocal';
  bool contains(DateTime instant) =>
      !instant.isBefore(effectiveFrom) &&
      (effectiveTo == null || instant.isBefore(effectiveTo!));

  bool overlaps(Regimen other) =>
      medicationId == other.medicationId &&
      (effectiveTo == null || other.effectiveFrom.isBefore(effectiveTo!)) &&
      (other.effectiveTo == null || effectiveFrom.isBefore(other.effectiveTo!));

  Regimen endingAt(DateTime end) => Regimen(
    id: id,
    medicationId: medicationId,
    amount: amount,
    unit: unit,
    kind: kind,
    effectiveFrom: effectiveFrom,
    effectiveTo: end,
    instructions: instructions,
    reminderEnabled: reminderEnabled,
    rules: rules,
  );

  Administration record({
    required String eventId,
    required Medication medication,
    required AdministrationStatus status,
    required DateTime recordedAt,
    DateTime? takenAt,
    DateTime? occurredAt,
    String notes = '',
    double? actualAmount,
    String? actualUnit,
    String? occurrenceKey,
    DateTime? intendedAt,
    String? originalZoneLabel,
    int? originalOffsetMinutes,
  }) {
    if (medication.id != medicationId) {
      throw ArgumentError('Medication mismatch.');
    }
    if (!contains(occurredAt ?? takenAt ?? recordedAt)) {
      throw ArgumentError('Regimen is not effective at this time.');
    }
    return Administration(
      id: eventId,
      medicationId: medicationId,
      medicationNameSnapshot: medication.name,
      medicationSnapshot: medication,
      status: status,
      recordedAt: recordedAt,
      takenAt: takenAt,
      occurredAt: occurredAt,
      notes: notes,
      amount: actualAmount ?? amount,
      unit: actualUnit ?? unit,
      regimenId: id,
      regimenSnapshot: this,
      occurrenceKey: occurrenceKey,
      intendedAt: intendedAt,
      originalZoneLabel: originalZoneLabel,
      originalOffsetMinutes: originalOffsetMinutes,
    );
  }
}
