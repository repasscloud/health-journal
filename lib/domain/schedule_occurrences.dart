import 'medication.dart';
import 'regimen.dart';

final class ScheduleOccurrence {
  const ScheduleOccurrence(this.key, this.at);
  final String key;
  final DateTime at;
}

/// Device-local wall time. Skipped clock minutes produce no occurrence.
/// Repeated clock minutes use the earlier instant. The key identifies the
/// regimen and wall-clock slot, including when a traveller changes timezone.
List<ScheduleOccurrence> occurrencesForDate(
  Regimen regimen,
  DateTime date, {
  DateTime Function(DateTime)? localize,
  Duration Function(DateTime)? offsetAt,
}) {
  final civilDate = DateTime.utc(date.year, date.month, date.day);
  final toWall = localize ?? (instant) => instant.toLocal();
  final offset = offsetAt ?? (instant) => instant.toLocal().timeZoneOffset;
  final offsets = {
    for (var hours = -36; hours <= 36; hours += 6)
      offset(civilDate.add(Duration(hours: hours))),
  };
  final occurrences = <ScheduleOccurrence>[];
  for (final rule in regimen.rules) {
    if (!rule.weekdays.contains(civilDate.weekday)) continue;
    final wall = civilDate.add(
      Duration(hours: rule.hour, minutes: rule.minute),
    );
    final candidates = offsets.map(wall.subtract).where((instant) {
      final local = toWall(instant);
      return local.year == wall.year &&
          local.month == wall.month &&
          local.day == wall.day &&
          local.hour == wall.hour &&
          local.minute == wall.minute;
    }).toList()..sort();
    if (candidates.isEmpty || !regimen.contains(candidates.first)) continue;
    occurrences.add(
      ScheduleOccurrence(
        '${regimen.id}:${civilDate.toIso8601String().split('T').first}:${rule.localTime}',
        candidates.first,
      ),
    );
  }
  return occurrences..sort((a, b) => a.at.compareTo(b.at));
}

/// Only the end of each explicit correction chain describes the current
/// outcome. Repository reads do not have to return rows in insertion order.
Map<String, AdministrationStatus> occurrenceOutcomes(
  Iterable<Administration> events,
) {
  final superseded = events.map((event) => event.correctsId).toSet();
  return {
    for (final event in events)
      if (!superseded.contains(event.id)) ?event.occurrenceKey: event.status,
  };
}
