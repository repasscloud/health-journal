import '../../domain/administration_snapshots.dart';
import '../../domain/medication.dart';
import '../../domain/measurement_units.dart';
import '../../domain/regimen.dart';
import '../../domain/records.dart';
import '../repositories/journal_repository.dart';
import '../repositories/journal_timeline.dart';

/// One fresh, volatile fixture per boot. No storage or native service imports.
final class DemoRepository implements JournalRepository {
  DemoRepository({bool richFixture = false}) {
    _medications.add(
      Medication(
        id: '00000000-0000-4000-8000-000000000001',
        name: 'Sample medication',
        strength: 'Sample strength',
        form: 'Tablet',
        createdAt: DateTime.utc(2020, 1, 1),
      ),
    );
    if (richFixture) _seedReview();
  }
  void _seedReview() {
    // Fixed invented dates and stable IDs: never copied from patient records.
    final anchor = DateTime.utc(2026, 11, 1);
    for (final kind in ScheduleKind.values) {
      final medication = Medication(
        id: 'review-med-${kind.name}',
        name: 'Sample ${kind.name} medication',
        strength: '10',
        strengthUnit: 'sample units',
        form: 'sample tablet',
        instructions: 'Example directions',
        createdAt: anchor,
      );
      saveMedication(medication);
      final regimen = Regimen(
        id: 'review-regimen-${kind.name}',
        medicationId: medication.id,
        amount: 1,
        unit: 'sample tablet',
        kind: kind,
        effectiveFrom: anchor,
        effectiveTo: kind == ScheduleKind.course
            ? anchor.add(const Duration(days: 5))
            : null,
        rules: kind == ScheduleKind.prn
            ? []
            : [
                ScheduleRule(
                  hour: 8,
                  minute: 0,
                  weekdays: {1, 2, 3, 4, 5, 6, 7},
                ),
                ScheduleRule(
                  hour: 18,
                  minute: 0,
                  weekdays: {1, 2, 3, 4, 5, 6, 7},
                ),
              ],
      );
      addRegimen(regimen);
      final eventTime = anchor.add(const Duration(days: 1, hours: 8));
      final original = regimen.record(
        eventId: 'review-event-${kind.name}',
        medication: medication,
        status: AdministrationStatus.skipped,
        recordedAt: eventTime,
        occurredAt: eventTime,
        notes: 'Sample administration',
      );
      recordAdministration(original);
      if (kind == ScheduleKind.fixed) {
        saveMedication(
          Medication(
            id: medication.id,
            name: 'Sample scheduled medication',
            strength: medication.strength,
            strengthUnit: medication.strengthUnit,
            form: medication.form,
            createdAt: medication.createdAt,
            updatedAt: eventTime.add(const Duration(hours: 2)),
            notes: 'Catalogue details updated',
          ),
        );
        recordAdministration(
          Administration(
            id: 'review-correction',
            medicationId: original.medicationId,
            medicationNameSnapshot: original.medicationNameSnapshot,
            medicationSnapshot: original.medicationSnapshot,
            regimenId: original.regimenId,
            regimenSnapshot: original.regimenSnapshot,
            status: AdministrationStatus.taken,
            recordedAt: eventTime.add(const Duration(hours: 1)),
            occurredAt: eventTime,
            takenAt: eventTime,
            amount: 1,
            unit: original.unit,
            correctsId: original.id,
            correctionReason: 'Status corrected after review',
          ),
        );
      }
    }
    addSymptom(
      SymptomEntry(
        id: 'review-symptom',
        title: 'Shoulder and back ache',
        onsetAt: anchor.add(const Duration(days: 2)),
        recordedAt: anchor.add(const Duration(days: 2)),
        severity: 4,
        notes: 'First noticed after gardening.',
        pain: [
          PainObservation(
            id: 'review-front',
            view: 'front',
            x: .5,
            y: .3,
            severity: 3,
          ),
          PainObservation(
            id: 'review-back',
            view: 'back',
            x: .5,
            y: .4,
            severity: 4,
          ),
          PainObservation(
            id: 'review-leg',
            view: 'back',
            x: .4,
            y: .7,
            severity: 2,
          ),
        ],
      ),
    );
    for (final kind in MeasurementKind.values) {
      addMeasurement(
        Measurement(
          id: 'review-measure-${kind.name}',
          kind: kind,
          value: switch (kind) {
            MeasurementKind.weight => 72,
            MeasurementKind.bloodPressure => 120,
            MeasurementKind.heartRate => 68,
            MeasurementKind.temperature => 36.7,
            MeasurementKind.glucose => 5.2,
            MeasurementKind.sleep => 7.5,
          },
          secondary: kind == MeasurementKind.bloodPressure ? 80 : null,
          unit: Measurement.units[kind]!,
          measuredAt: anchor.add(const Duration(days: 3)),
          recordedAt: anchor.add(const Duration(days: 3)),
        ),
      );
    }
  }

  var _preferences = const JournalPreferences();

  @override
  JournalPreferences get preferences => _preferences;

  @override
  void savePreferences(JournalPreferences preferences) {
    _preferences = preferences;
  }

  final List<SymptomEntry> _symptoms = [];
  final List<SymptomEntry> _symptomHistory = [];
  final List<Measurement> _measurements = [];
  @override
  List<SymptomEntry> get symptoms => List.unmodifiable(_symptoms);
  @override
  List<Measurement> get measurements => List.unmodifiable(_measurements);
  @override
  void addSymptom(SymptomEntry symptom) {
    if (_symptoms.any((s) => s.id == symptom.id)) {
      throw StateError('Duplicate symptom.');
    }
    _symptoms.add(symptom);
  }

  @override
  List<SymptomEntry> symptomHistory(String id) =>
      List.unmodifiable(_symptomHistory.where((entry) => entry.id == id));

  @override
  void reviseSymptom(SymptomEntry symptom) {
    final index = _symptoms.indexWhere((entry) => entry.id == symptom.id);
    if (index < 0) throw StateError('Symptom could not be found.');
    final previous = _symptoms[index];
    if (symptom.recordedAt != previous.recordedAt ||
        !symptom.updatedAt.isAfter(previous.updatedAt)) {
      throw StateError('Symptom revision dates are invalid.');
    }
    _symptomHistory.add(previous);
    _symptoms[index] = symptom;
  }

  @override
  void addMeasurement(Measurement measurement) {
    if (_measurements.any((m) => m.id == measurement.id)) {
      throw StateError('Duplicate measurement.');
    }
    _measurements.add(measurement);
  }

  @override
  List<TimelineItem> timeline({String search = ''}) => journalTimeline(
    administrations: _administrations,
    regimens: _regimens,
    regimenName: (regimen) => _regimenNames[regimen.id]!,
    symptoms: _symptoms,
    measurements: _measurements,
    search: search,
  );

  final List<Medication> _medications = [];
  final List<Medication> _medicationHistory = [];
  @override
  List<Medication> get medicationHistory =>
      List.unmodifiable(_medicationHistory);
  final List<Regimen> _regimens = [];
  final Map<String, String> _regimenNames = {};
  @override
  List<Regimen> get regimens => List.unmodifiable(_regimens);
  @override
  void reviseRegimen(String previousId, Regimen revision) {
    final index = _regimens.indexWhere((r) => r.id == previousId);
    if (index < 0) throw StateError('Previous regimen is unavailable.');
    final previous = _regimens[index];
    if (previous.medicationId != revision.medicationId ||
        !previous.contains(revision.effectiveFrom) ||
        !revision.effectiveFrom.isAfter(previous.effectiveFrom) ||
        _regimens.any(
          (r) =>
              r.id == revision.id ||
              (r.id != previousId && r.overlaps(revision)),
        )) {
      throw StateError('Revision conflicts with effective dates or IDs.');
    }
    final closed = previous.endingAt(revision.effectiveFrom);
    _regimens[index] = closed;
    _regimens.add(revision);
    _regimenNames[revision.id] = _medications
        .firstWhere((m) => m.id == revision.medicationId)
        .name;
  }

  @override
  void addRegimen(Regimen regimen) {
    if (!_medications.any((m) => m.id == regimen.medicationId)) {
      throw StateError('Medication does not exist.');
    }
    if (_regimens.any((r) => r.id == regimen.id || r.overlaps(regimen))) {
      throw StateError(
        'Regimens must have distinct IDs and non-overlapping effective dates.',
      );
    }
    _regimens.add(regimen);
    _regimenNames[regimen.id] = _medications
        .firstWhere((m) => m.id == regimen.medicationId)
        .name;
  }

  final List<Administration> _administrations = [];
  @override
  List<Medication> get medications => List.unmodifiable(_medications);
  @override
  List<Administration> get administrations =>
      List.unmodifiable(_administrations);
  @override
  void saveMedication(Medication medication) {
    final index = _medications.indexWhere((m) => m.id == medication.id);
    if (index == -1) {
      _medications.add(medication);
    } else {
      final previous = _medications[index];
      if (medication.createdAt != previous.createdAt ||
          medication.updatedAt.isBefore(previous.updatedAt)) {
        throw StateError(
          'Catalogue timestamps must preserve creation and revision order.',
        );
      }
      _medicationHistory.add(previous);
      _medications[index] = medication;
    }
  }

  @override
  void recordAdministration(Administration event) {
    if (!_medications.any((m) => m.id == event.medicationId)) {
      throw StateError('Medication does not exist.');
    }
    if (_administrations.any((e) => e.id == event.id)) {
      throw StateError('This event is already recorded.');
    }
    if (event.regimenId != null &&
        !_regimens.any(
          (r) =>
              r.id == event.regimenId &&
              r.medicationId == event.medicationId &&
              r.contains(event.occurredAt),
        )) {
      throw StateError('Regimen is unavailable at the event time.');
    }
    if (event.correctsId == null &&
        event.occurrenceKey != null &&
        _administrations.any(
          (other) => other.occurrenceKey == event.occurrenceKey,
        )) {
      throw StateError('This scheduled occurrence already has an entry.');
    }
    if (event.correctsId != null) {
      final originals = _administrations.where((e) => e.id == event.correctsId);
      if (originals.isEmpty ||
          _administrations.any((e) => e.correctsId == event.correctsId)) {
        throw StateError('Correction target missing or already corrected.');
      }
      final original = originals.single;
      if (event.medicationId != original.medicationId ||
          event.occurrenceKey != original.occurrenceKey ||
          event.intendedAt != original.intendedAt ||
          event.medicationNameSnapshot != original.medicationNameSnapshot ||
          _catalogueValue(event.medicationSnapshot) !=
              _catalogueValue(original.medicationSnapshot) ||
          event.regimenId != original.regimenId ||
          _regimenValue(event.regimenSnapshot) !=
              _regimenValue(original.regimenSnapshot) ||
          event.recordedAt.isBefore(original.recordedAt)) {
        throw StateError('Corrections must preserve original snapshots.');
      }
    }
    _administrations.add(event);
  }
}

String? _catalogueValue(Medication? value) =>
    value == null ? null : AdministrationSnapshots.catalogue(value);

String? _regimenValue(Regimen? value) =>
    value == null ? null : AdministrationSnapshots.schedule(value);
