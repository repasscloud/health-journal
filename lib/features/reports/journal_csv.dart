import 'dart:convert';
import 'dart:typed_data';

import '../../data/repositories/journal_repository.dart';
import '../../domain/records.dart';

/// A UTF-8 export with canonical units and the original facts for revisions.
Uint8List journalCsv(JournalRepository repository) {
  final text = StringBuffer();
  void row(List<Object?> cells) {
    text.writeAll(cells.map(_cell), ',');
    text.write('\r\n');
  }

  void entry(
    String type,
    String id, {
    String? related,
    DateTime? occurred,
    DateTime? recorded,
    String? zone,
    int? offset,
    String? label,
    String? status,
    num? value,
    num? secondary,
    String? unit,
    String? mapVersion,
    String? mapView,
    double? x,
    double? y,
    double? radius,
    int? severity,
    String? notes,
  }) => row([
    type,
    id,
    related,
    occurred,
    recorded,
    zone,
    offset,
    label,
    status,
    value,
    secondary,
    unit,
    mapVersion,
    mapView,
    x,
    y,
    radius,
    severity,
    notes,
  ]);

  row([
    'record_type',
    'id',
    'related_id',
    'occurred_utc',
    'recorded_utc',
    'original_time_zone',
    'original_offset_minutes',
    'label',
    'status',
    'value',
    'secondary_value',
    'unit',
    'map_version',
    'map_view',
    'normalized_x',
    'normalized_y',
    'normalized_radius',
    'severity',
    'notes',
  ]);
  for (final (type, medication) in [
    for (final item in repository.medications) ('medication', item),
    for (final item in repository.medicationHistory)
      ('medication_revision', item),
  ]) {
    entry(
      type,
      medication.id,
      occurred: medication.createdAt,
      recorded: medication.updatedAt,
      label: medication.name,
      status: medication.archived ? 'archived' : 'listed',
      notes: [
        medication.strength,
        medication.strengthUnit,
        medication.form,
        medication.instructions,
        medication.notes,
      ].where((value) => value.isNotEmpty).join('\n'),
    );
  }
  for (final regimen in repository.regimens) {
    entry(
      'regimen',
      regimen.id,
      related: regimen.medicationId,
      occurred: regimen.effectiveFrom,
      status: regimen.kind.name,
      value: regimen.amount,
      unit: regimen.unit,
      zone: regimen.zonePolicy,
      notes: [
        if (regimen.effectiveTo case final end?)
          'Effective until ${end.toIso8601String()}',
        for (final rule in regimen.rules)
          '${rule.localTime} weekdays ${(rule.weekdays.toList()..sort()).join(',')}',
        regimen.instructions,
      ].where((value) => value.isNotEmpty).join('\n'),
    );
  }
  for (final dose in repository.administrations) {
    entry(
      dose.correctsId == null ? 'administration' : 'administration_correction',
      dose.id,
      related: dose.correctsId ?? dose.regimenId ?? dose.medicationId,
      occurred: dose.occurredAt,
      recorded: dose.recordedAt,
      zone: dose.originalZoneLabel,
      offset: dose.originalOffsetMinutes,
      label: dose.medicationNameSnapshot,
      status: dose.status.name,
      value: dose.amount,
      unit: dose.unit,
      notes: [
        if (dose.intendedAt case final intended?)
          'Scheduled ${intended.toIso8601String()}',
        dose.notes,
        dose.correctionReason,
      ].where((value) => value.isNotEmpty).join('\n'),
    );
  }
  final knownDoses = repository.administrations.map((dose) => dose.id).toSet();
  for (final item in repository.timeline()) {
    if (item.type == 'medication' && !knownDoses.contains(item.id)) {
      entry('legacy_administration', item.id, notes: item.text);
    }
  }
  void symptom(SymptomEntry item, {required bool current}) {
    entry(
      current ? 'symptom' : 'symptom_revision',
      item.id,
      label: item.title,
      occurred: item.onsetAt,
      recorded: item.updatedAt,
      severity: item.severity,
      notes: [
        if (item.endAt case final end?) 'Ended ${end.toIso8601String()}',
        item.category,
        item.triggers,
        item.relief,
        item.effect,
        item.notes,
      ].where((value) => value.isNotEmpty).join('\n'),
    );
    for (final point in item.pain) {
      entry(
        current ? 'pain_marker' : 'pain_marker_revision',
        point.id,
        related: item.id,
        occurred: item.onsetAt,
        recorded: item.updatedAt,
        label: point.region,
        status: point.painType,
        mapVersion: point.assetVersion,
        mapView: point.view,
        x: point.x,
        y: point.y,
        radius: point.radius,
        severity: point.severity,
        notes: point.laterality,
      );
    }
  }

  for (final item in repository.symptoms) {
    symptom(item, current: true);
    for (final previous in repository.symptomHistory(item.id)) {
      symptom(previous, current: false);
    }
  }
  for (final measurement in repository.measurements) {
    entry(
      'measurement',
      measurement.id,
      occurred: measurement.measuredAt,
      recorded: measurement.recordedAt,
      label: measurement.kind.name,
      status: measurement.source,
      value: measurement.value,
      secondary: measurement.secondary,
      unit: measurement.unit,
    );
  }
  return utf8.encode(text.toString());
}

final _formula = RegExp(r'^[=+\-@\t\r\n]');

String _cell(Object? value) {
  var text = switch (value) {
    null => '',
    final DateTime timestamp => timestamp.toUtc().toIso8601String(),
    _ => value.toString(),
  };
  if (value is String &&
      (_formula.hasMatch(text) || _formula.hasMatch(text.trimLeft()))) {
    text = "'$text";
  }
  return '"${text.replaceAll('"', '""')}"';
}
