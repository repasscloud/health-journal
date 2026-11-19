import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/administration_snapshots.dart';
import '../../domain/medication.dart';
import '../../domain/records.dart';
import '../../domain/regimen.dart';
import '../schema/journal_database.dart' as schema;

int _ticks(DateTime date) => date.microsecondsSinceEpoch;
DateTime _instant(int ticks) =>
    DateTime.fromMicrosecondsSinceEpoch(ticks, isUtc: true);
int? _optionalTicks(DateTime? date) => date?.microsecondsSinceEpoch;
DateTime? _optionalInstant(int? ticks) =>
    ticks == null ? null : _instant(ticks);

/// Transactional persistence for native record facts and revisions.
final class NativeRecords {
  NativeRecords(this._db);
  final schema.JournalDatabase _db;

  Future<List<Medication>> medications() async =>
      (await _db.select(_db.medications).get()).map(_medication).toList();

  Future<List<Regimen>> regimens() async => [
    for (final row in await (_db.select(
      _db.medicationRegimens,
    )..where((row) => row.zonePolicy.isNotNull())).get())
      (await regimen(row.id))!,
  ];

  Future<List<SymptomEntry>> symptoms() async => [
    for (final row in await _db.select(_db.symptomEntries).get())
      (await symptom(row.id))!,
  ];

  Future<List<Measurement>> measurements() async => [
    for (final row in await _db.select(_db.measurements).get())
      (await measurement(row.id))!,
  ];

  Future<Medication?> medication(String id) async {
    final row = await (_db.select(
      _db.medications,
    )..where((entry) => entry.id.equals(id))).getSingleOrNull();
    return row == null ? null : _medication(row);
  }

  Medication _medication(schema.Medication row) => Medication(
    id: row.id,
    name: row.name,
    strength: row.strength,
    createdAt: _instant(row.createdAt),
    updatedAt: _instant(row.updatedAt),
    archived: row.archived != 0,
    genericName: row.genericName ?? '',
    brand: row.brand ?? '',
    form: row.form ?? '',
    strengthUnit: row.strengthUnit ?? '',
    instructions: row.instructions ?? '',
    reason: row.reason ?? '',
    prescribedBy: row.prescribedBy ?? '',
    notes: row.notes ?? '',
    startedAt: _optionalInstant(row.startedAt),
    stoppedAt: _optionalInstant(row.stoppedAt),
    pausedAt: _optionalInstant(row.pausedAt),
  );

  Future<void> saveMedication(Medication value) => _db.transaction(() async {
    final previous = await medication(value.id);
    if (previous != null) {
      if (previous.createdAt != value.createdAt ||
          !value.updatedAt.isAfter(previous.updatedAt)) {
        throw StateError('Catalogue revision dates are invalid.');
      }
      await _audit(
        'medication',
        value.id,
        value.updatedAt,
        AdministrationSnapshots.catalogue(previous),
      );
    }
    await _db
        .into(_db.medications)
        .insertOnConflictUpdate(
          schema.MedicationsCompanion.insert(
            id: value.id,
            name: value.name,
            strength: value.strength,
            createdAt: _ticks(value.createdAt),
            updatedAt: _ticks(value.updatedAt),
            archived: Value(value.archived ? 1 : 0),
            genericName: Value(value.genericName),
            brand: Value(value.brand),
            form: Value(value.form),
            strengthUnit: Value(value.strengthUnit),
            instructions: Value(value.instructions),
            reason: Value(value.reason),
            prescribedBy: Value(value.prescribedBy),
            notes: Value(value.notes),
            startedAt: Value(_optionalTicks(value.startedAt)),
            stoppedAt: Value(_optionalTicks(value.stoppedAt)),
            pausedAt: Value(_optionalTicks(value.pausedAt)),
          ),
        );
  });

  Future<List<Medication>> medicationHistory(String id) async =>
      (await _snapshots(
        'medication',
        id,
      )).map(AdministrationSnapshots.readCatalogue).toList();

  Future<Regimen?> regimen(String id) async {
    final row = await (_db.select(
      _db.medicationRegimens,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    if (row.zonePolicy == null) {
      throw StateError('Legacy regimen has no structured schedule history.');
    }
    final weekdays = <int, Set<int>>{};
    final rules =
        await (_db.select(_db.medicationScheduleRules)
              ..where((r) => r.regimenId.equals(id))
              ..orderBy([(r) => OrderingTerm.asc(r.minuteOfDay)]))
            .get();
    for (final rule in rules) {
      weekdays.putIfAbsent(rule.minuteOfDay, () => {}).add(rule.weekday);
    }
    return Regimen(
      id: row.id,
      medicationId: row.medicationId,
      amount: row.amount,
      unit: row.unit,
      kind: ScheduleKind.values.byName(row.kind),
      effectiveFrom: _instant(row.effectiveFrom),
      effectiveTo: _optionalInstant(row.effectiveTo),
      instructions: row.instructionsSnapshot,
      reminderEnabled: row.reminderEnabled == 1,
      rules: [
        for (final rule in weekdays.entries)
          ScheduleRule(
            hour: rule.key ~/ 60,
            minute: rule.key % 60,
            weekdays: rule.value,
          ),
      ],
    );
  }

  Future<void> addRegimen(Regimen value) =>
      _db.transaction(() => _insertRegimen(value));

  Future<void> reviseRegimen(String previousId, Regimen value) =>
      _db.transaction(() async {
        final previous = await regimen(previousId);
        if (previous == null ||
            previous.medicationId != value.medicationId ||
            !previous.contains(value.effectiveFrom) ||
            !value.effectiveFrom.isAfter(previous.effectiveFrom)) {
          throw StateError('Regimen revision is outside the original range.');
        }
        await (_db.update(
          _db.medicationRegimens,
        )..where((r) => r.id.equals(previousId))).write(
          schema.MedicationRegimensCompanion(
            effectiveTo: Value(_ticks(value.effectiveFrom)),
          ),
        );
        await _insertRegimen(value);
      });

  Future<void> _insertRegimen(Regimen value) async {
    final current = await (_db.select(
      _db.medicationRegimens,
    )..where((r) => r.medicationId.equals(value.medicationId))).get();
    final start = _ticks(value.effectiveFrom);
    final end = _optionalTicks(value.effectiveTo);
    if (current.any(
      (r) =>
          r.zonePolicy == null ||
          ((r.effectiveTo == null || start < r.effectiveTo!) &&
              (end == null || r.effectiveFrom < end)),
    )) {
      throw StateError('Overlapping or unversioned regimen.');
    }
    await _db
        .into(_db.medicationRegimens)
        .insert(
          schema.MedicationRegimensCompanion.insert(
            id: value.id,
            medicationId: value.medicationId,
            amount: value.amount,
            unit: value.unit,
            kind: value.kind.name,
            effectiveFrom: start,
            effectiveTo: Value(end),
            instructionsSnapshot: value.instructions,
            zonePolicy: Value(value.zonePolicy),
            reminderEnabled: Value(value.reminderEnabled ? 1 : 0),
          ),
        );
    await _db.batch(
      (batch) => batch.insertAll(_db.medicationScheduleRules, [
        for (final rule in value.rules)
          for (final day in rule.weekdays)
            schema.MedicationScheduleRulesCompanion.insert(
              id: const Uuid().v4(),
              regimenId: value.id,
              weekday: day,
              minuteOfDay: rule.hour * 60 + rule.minute,
            ),
      ]),
    );
  }

  Future<SymptomEntry?> symptom(String id) => _db.transaction(() async {
    final row = await (_db.select(
      _db.symptomEntries,
    )..where((entry) => entry.id.equals(id))).getSingleOrNull();
    return row == null ? null : _symptom(row, await _markers(id));
  });

  Future<List<schema.PainMarker>> _markers(String id) =>
      (_db.select(_db.painMarkers)
            ..where((p) => p.symptomId.equals(id))
            ..orderBy([(p) => OrderingTerm.asc(p.rowId)]))
          .get();

  SymptomEntry _symptom(
    schema.SymptomEntry row,
    List<schema.PainMarker> markers,
  ) => SymptomEntry(
    id: row.id,
    title: row.title,
    notes: row.notes,
    onsetAt: _instant(row.onsetAt),
    endAt: _optionalInstant(row.endAt),
    recordedAt: _instant(row.recordedAt),
    updatedAt: _instant(row.updatedAt),
    severity: row.severity,
    category: row.category ?? '',
    pattern: row.pattern,
    triggers: row.triggers ?? '',
    relief: row.reliefMeasures ?? '',
    effect: row.perceivedEffect ?? '',
    pain: [
      for (final p in markers)
        PainObservation(
          id: p.id,
          view: p.bodyView,
          x: p.x,
          y: p.y,
          assetVersion: p.bodyAssetVersion,
          severity: p.severity,
          painType: p.painType,
          radius: p.radius == 0 ? null : p.radius,
        ),
    ],
  );

  Future<void> saveSymptom(SymptomEntry value) => _db.transaction(() async {
    final previous = await (_db.select(
      _db.symptomEntries,
    )..where((entry) => entry.id.equals(value.id))).getSingleOrNull();
    if (previous != null) {
      if (previous.recordedAt != _ticks(value.recordedAt) ||
          previous.updatedAt >= _ticks(value.updatedAt)) {
        throw StateError('Symptom revision dates are invalid.');
      }
      final points = await _markers(value.id);
      await _audit(
        'symptom',
        value.id,
        value.updatedAt,
        jsonEncode({
          'version': 1,
          'symptom': previous.toJson(),
          'markers': points.map((p) => p.toJson()).toList(),
        }),
      );
      await (_db.delete(
        _db.painMarkers,
      )..where((p) => p.symptomId.equals(value.id))).go();
    }
    await _db
        .into(_db.symptomEntries)
        .insertOnConflictUpdate(
          schema.SymptomEntriesCompanion.insert(
            id: value.id,
            title: value.title,
            onsetAt: _ticks(value.onsetAt),
            endAt: Value(_optionalTicks(value.endAt)),
            recordedAt: _ticks(value.recordedAt),
            updatedAt: _ticks(value.updatedAt),
            severity: Value(value.severity),
            notes: Value(value.notes),
            category: Value(value.category),
            pattern: Value(value.pattern),
            triggers: Value(value.triggers),
            reliefMeasures: Value(value.relief),
            perceivedEffect: Value(value.effect),
          ),
        );
    await _db.batch(
      (batch) => batch.insertAll(_db.painMarkers, [
        for (final point in value.pain)
          schema.PainMarkersCompanion.insert(
            id: point.id,
            symptomId: value.id,
            bodyView: point.view,
            x: point.x,
            y: point.y,
            radius: Value(point.radius),
            bodyAssetVersion: point.assetVersion,
            regionCode: point.region,
            laterality: point.laterality,
            severity: point.severity,
            painType: point.painType,
          ),
      ]),
    );
  });

  Future<List<SymptomEntry>> symptomHistory(String id) async => [
    for (final snapshot in await _snapshots('symptom', id))
      _readSymptomSnapshot(snapshot),
  ];

  SymptomEntry _readSymptomSnapshot(String snapshot) {
    final json = jsonDecode(snapshot) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unsupported symptom snapshot.');
    }
    return _symptom(
      schema.SymptomEntry.fromJson(json['symptom'] as Map<String, dynamic>),
      (json['markers'] as List)
          .cast<Map<String, dynamic>>()
          .map(schema.PainMarker.fromJson)
          .toList(),
    );
  }

  Future<void> addMeasurement(Measurement value) async {
    await _db
        .into(_db.measurements)
        .insert(
          schema.MeasurementsCompanion.insert(
            id: value.id,
            kind: value.kind.name,
            value: value.value,
            secondary: Value(value.secondary),
            measuredAt: _ticks(value.measuredAt),
            recordedAt: _ticks(value.recordedAt),
          ),
        );
  }

  Future<Measurement?> measurement(String id) async {
    final row = await (_db.select(
      _db.measurements,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final kind = MeasurementKind.values.byName(row.kind);
    return Measurement(
      id: row.id,
      kind: kind,
      value: row.value,
      secondary: row.secondary,
      unit: Measurement.units[kind]!,
      measuredAt: _instant(row.measuredAt),
      recordedAt: _instant(row.recordedAt),
    );
  }

  Future<void> _audit(String type, String id, DateTime at, String value) async {
    await _db
        .into(_db.auditEvents)
        .insert(
          schema.AuditEventsCompanion.insert(
            id: const Uuid().v4(),
            recordType: type,
            recordId: id,
            actionCode: 'revise',
            recordedAt: _ticks(at),
            snapshot: Value(value),
          ),
        );
  }

  Future<Iterable<String>> _snapshots(String type, String id) async =>
      (await (_db.select(_db.auditEvents)
                ..where(
                  (event) =>
                      event.recordType.equals(type) &
                      event.recordId.equals(id) &
                      event.actionCode.equals('revise'),
                )
                ..orderBy([(event) => OrderingTerm.asc(event.recordedAt)]))
              .get())
          .map((event) => event.snapshot)
          .whereType<String>();
}
