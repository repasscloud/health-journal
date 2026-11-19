import 'package:drift/drift.dart';

import '../../domain/medication.dart';
import '../../domain/measurement_units.dart';
import '../../domain/records.dart';
import '../../domain/regimen.dart';
import '../schema/journal_database.dart'
    show JournalDatabase, JournalSettingsCompanion;
import 'journal_repository.dart';
import 'journal_timeline.dart';
import 'native_medication_history.dart';
import 'native_records.dart';

/// Read snapshot for the shared UI. Every write and snapshot refresh passes
/// through the same encrypted transaction before publishing new state.
final class NativeJournalRepository implements JournalRepository {
  NativeJournalRepository._(this._db)
    : _records = NativeRecords(_db),
      _doses = NativeMedicationHistory(_db);

  static Future<NativeJournalRepository> load(JournalDatabase db) async {
    final repository = NativeJournalRepository._(db);
    await repository._write(() async {});
    return repository;
  }

  final JournalDatabase _db;
  final NativeRecords _records;
  final NativeMedicationHistory _doses;
  Future<void> _pending = Future.value();
  late _JournalSnapshot _snapshot;
  Future<void> get pendingWrites => _pending;

  Future<void> _write(Future<void> Function() write) {
    final result = _pending.then((_) async {
      _snapshot = await _db.transaction(() async {
        await write();
        final medications = await _records.medications();
        final symptoms = await _records.symptoms();
        final events = await _doses.all();
        final settings = await _db
            .select(_db.journalSettings)
            .getSingleOrNull();
        return _JournalSnapshot(
          preferences: settings == null
              ? const JournalPreferences()
              : JournalPreferences(
                  units: MeasurementUnits(
                    weight: settings.weightUnit == 'lb'
                        ? DisplayUnit.pounds
                        : DisplayUnit.kilograms,
                    temperature: settings.temperatureUnit == 'fahrenheit'
                        ? DisplayUnit.fahrenheit
                        : DisplayUnit.celsius,
                    glucose: settings.glucoseUnit == 'mg/dL'
                        ? DisplayUnit.mgPerDeciliter
                        : DisplayUnit.mmolPerLiter,
                  ),
                  appearance: JournalAppearance.values.byName(
                    settings.appearance,
                  ),
                ),
          medications: List.unmodifiable(medications),
          medicationHistory: List.unmodifiable([
            for (final medication in medications)
              ...await _records.medicationHistory(medication.id),
          ]),
          regimens: List.unmodifiable(await _records.regimens()),
          symptoms: List.unmodifiable(symptoms),
          symptomHistory: {
            for (final symptom in symptoms)
              symptom.id: List.unmodifiable(
                await _records.symptomHistory(symptom.id),
              ),
          },
          measurements: List.unmodifiable(await _records.measurements()),
          administrations: List.unmodifiable([
            for (final event in events)
              if (event.catalogue != null) _administration(event),
          ]),
          legacyEvents: [
            for (final event in events)
              if (event.catalogue == null)
                TimelineItem(
                  event.row.id,
                  _instant(event.row.occurredAt ?? event.row.recordedAt),
                  'medication',
                  'Historical medication entry • ${event.status.name} • '
                      '${event.row.amount} ${event.row.unit}'
                      '${event.row.occurredAt == null ? ' • Date entered (event time unavailable)' : ''}',
                ),
          ],
        );
      });
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static DateTime _instant(int ticks) =>
      DateTime.fromMicrosecondsSinceEpoch(ticks, isUtc: true);
  static DateTime? _optionalInstant(int? ticks) =>
      ticks == null ? null : _instant(ticks);

  static Administration _administration(StoredAdministration event) {
    final row = event.row;
    return Administration(
      id: row.id,
      medicationId: row.medicationId,
      medicationNameSnapshot: event.catalogue!.name,
      medicationSnapshot: event.catalogue,
      status: event.status,
      recordedAt: _instant(row.recordedAt),
      occurredAt: _instant(row.occurredAt!),
      takenAt: _optionalInstant(row.takenAt),
      amount: row.amount,
      unit: row.unit,
      regimenId: row.regimenId,
      regimenSnapshot: event.regimen,
      notes: row.notes ?? '',
      correctsId: row.correctsId,
      correctionReason: row.correctionReason ?? '',
      occurrenceKey: row.occurrenceKey,
      intendedAt: _optionalInstant(row.intendedAt),
      originalZoneLabel: row.originalZoneLabel,
      originalOffsetMinutes: row.originalOffsetMinutes,
    );
  }

  @override
  JournalPreferences get preferences => _snapshot.preferences;

  @override
  Future<void> savePreferences(JournalPreferences preferences) =>
      _write(() async {
        final units = preferences.units;
        await _db
            .into(_db.journalSettings)
            .insertOnConflictUpdate(
              JournalSettingsCompanion(
                singleton: const Value(1),
                weightUnit: Value(units.weight.symbol),
                temperatureUnit: Value(units.temperature.name),
                glucoseUnit: Value(units.glucose.symbol),
                appearance: Value(preferences.appearance.name),
              ),
            );
      });

  @override
  List<Medication> get medications => _snapshot.medications;
  @override
  List<Medication> get medicationHistory => _snapshot.medicationHistory;
  @override
  List<Regimen> get regimens => _snapshot.regimens;
  @override
  List<Administration> get administrations => _snapshot.administrations;
  @override
  List<SymptomEntry> get symptoms => _snapshot.symptoms;
  @override
  List<Measurement> get measurements => _snapshot.measurements;
  @override
  List<SymptomEntry> symptomHistory(String id) =>
      _snapshot.symptomHistory[id] ?? const [];

  @override
  List<TimelineItem> timeline({String search = ''}) {
    final names = {for (final item in medications) item.id: item.name};
    final items = [
      ...journalTimeline(
        administrations: administrations,
        regimens: regimens,
        regimenName: (regimen) => names[regimen.medicationId]!,
        symptoms: symptoms,
        measurements: measurements,
        search: search,
      ),
      ..._snapshot.legacyEvents.where(
        (item) => '${item.type} ${item.text}'.toLowerCase().contains(
          search.trim().toLowerCase(),
        ),
      ),
    ];
    items.sort((a, b) {
      final order = b.at.compareTo(a.at);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return List.unmodifiable(items);
  }

  @override
  Future<void> saveMedication(Medication medication) =>
      _write(() => _records.saveMedication(medication));
  @override
  Future<void> addRegimen(Regimen regimen) =>
      _write(() => _records.addRegimen(regimen));
  @override
  Future<void> reviseRegimen(String previousId, Regimen revision) =>
      _write(() => _records.reviseRegimen(previousId, revision));
  @override
  Future<void> recordAdministration(Administration event) =>
      _write(() => _doses.append(event));
  @override
  Future<void> addSymptom(SymptomEntry symptom) => _write(() async {
    if (await _records.symptom(symptom.id) != null) {
      throw StateError('Duplicate symptom.');
    }
    await _records.saveSymptom(symptom);
  });
  @override
  Future<void> reviseSymptom(SymptomEntry symptom) => _write(() async {
    if (await _records.symptom(symptom.id) == null) {
      throw StateError('Symptom could not be found.');
    }
    await _records.saveSymptom(symptom);
  });
  @override
  Future<void> addMeasurement(Measurement measurement) =>
      _write(() => _records.addMeasurement(measurement));
}

final class _JournalSnapshot {
  const _JournalSnapshot({
    required this.preferences,
    required this.medications,
    required this.medicationHistory,
    required this.regimens,
    required this.symptoms,
    required this.symptomHistory,
    required this.measurements,
    required this.administrations,
    required this.legacyEvents,
  });

  final JournalPreferences preferences;
  final List<Medication> medications, medicationHistory;
  final List<Regimen> regimens;
  final List<SymptomEntry> symptoms;
  final Map<String, List<SymptomEntry>> symptomHistory;
  final List<Measurement> measurements;
  final List<Administration> administrations;
  final List<TimelineItem> legacyEvents;
}
