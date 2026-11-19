import 'medication.dart';
import 'regimen.dart';
import 'schedule_occurrences.dart';

/// Builds a rolling queue of private wake-up times from explicitly opted-in
/// regimens. A reminder is a scheduled slot, never an administration event.
List<ScheduleOccurrence> planMedicationReminders({
  required DateTime now,
  required Iterable<Medication> medications,
  required Iterable<Regimen> regimens,
  required Set<String> enabledRegimenIds,
  required Iterable<Administration> administrations,
}) {
  const horizonDays = 7;
  const maximumPending = 64;
  final deadline = now.add(const Duration(days: horizonDays));
  final localNow = now.toLocal();
  final eligibleMedicationIds = {
    for (final medication in medications)
      if (!medication.archived) medication.id,
  };
  final recordedKeys = {
    for (final administration in administrations) ?administration.occurrenceKey,
  };
  final occurrences = <String, ScheduleOccurrence>{};
  for (final regimen in regimens) {
    if (!enabledRegimenIds.contains(regimen.id) ||
        !eligibleMedicationIds.contains(regimen.medicationId) ||
        regimen.kind == ScheduleKind.prn) {
      continue;
    }
    // Include the civil boundary at both ends. The instant filter handles
    // shorter or longer local days without extending the elapsed window.
    for (var day = 0; day <= horizonDays + 1; day++) {
      final date = DateTime.utc(
        localNow.year,
        localNow.month,
        localNow.day + day,
      );
      for (final slot in occurrencesForDate(regimen, date)) {
        if (slot.at.isAfter(now) &&
            !slot.at.isAfter(deadline) &&
            !recordedKeys.contains(slot.key)) {
          occurrences[slot.key] = slot;
        }
      }
    }
  }
  final sorted = occurrences.values.toList()
    ..sort((a, b) {
      final byInstant = a.at.compareTo(b.at);
      return byInstant == 0 ? a.key.compareTo(b.key) : byInstant;
    });
  return List.unmodifiable(sorted.take(maximumPending));
}
