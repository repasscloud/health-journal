import '../../domain/medication.dart';
import '../../domain/regimen.dart';
import '../../domain/records.dart';
import '../repositories/journal_repository.dart';

/// One fresh, volatile fixture per boot. No storage or native service imports.
final class DemoRepository implements JournalRepository {
  DemoRepository() {
    _medications.add(
      Medication(
        id: '00000000-0000-4000-8000-000000000001',
        name: 'Fictional sample medication',
        strength: 'Sample strength',
        createdAt: DateTime.utc(2026, 11, 17),
      ),
    );
  }
  final List<SymptomEntry> _symptoms = [];
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
  void addMeasurement(Measurement measurement) {
    if (_measurements.any((m) => m.id == measurement.id)) {
      throw StateError('Duplicate measurement.');
    }
    _measurements.add(measurement);
  }

  @override
  List<TimelineItem> timeline({String search = ''}) {
    final items =
        [
              for (final e in _administrations)
                TimelineItem(
                  e.id,
                  e.occurredAt,
                  'medication',
                  '${e.medicationNameSnapshot} • ${e.status.name} • ${e.amount} ${e.unit}${_administrations.any((c) => c.correctsId == e.id) ? ' • superseded' : ''}${e.correctsId != null ? ' • correction' : ''}',
                ),
              for (final r in _regimens)
                TimelineItem(
                  r.id,
                  r.effectiveFrom,
                  'schedule',
                  '${_medications.firstWhere((m) => m.id == r.medicationId).name} • ${r.kind.name} • ${r.amount} ${r.unit} • unconfirmed',
                ),
              for (final s in _symptoms)
                TimelineItem(
                  s.id,
                  s.onsetAt,
                  'symptom',
                  '${s.title} • ${s.notes} • ${s.pain.map((p) => '${p.view} ${p.region} ${p.severity}/10').join(', ')}',
                ),
              for (final m in _measurements)
                TimelineItem(
                  m.id,
                  m.measuredAt,
                  'measurement',
                  '${m.display} • manual',
                ),
            ]
            .where(
              (i) => '${i.type} ${i.text}'.toLowerCase().contains(
                search.trim().toLowerCase(),
              ),
            )
            .toList();
    items.sort((a, b) {
      final order = b.at.compareTo(a.at);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return List.unmodifiable(items);
  }

  final List<Medication> _medications = [];
  final List<Medication> _medicationHistory = [];
  @override
  List<Medication> get medicationHistory =>
      List.unmodifiable(_medicationHistory);
  final List<Regimen> _regimens = [];
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
              r.id == event.regimenId && r.medicationId == event.medicationId,
        )) {
      throw StateError('Regimen does not exist.');
    }
    if (event.correctsId != null) {
      final originals = _administrations.where((e) => e.id == event.correctsId);
      if (originals.isEmpty ||
          _administrations.any((e) => e.correctsId == event.correctsId)) {
        throw StateError('Correction target missing or already corrected.');
      }
      final original = originals.single;
      if (event.medicationId != original.medicationId ||
          event.medicationNameSnapshot != original.medicationNameSnapshot ||
          !identical(event.medicationSnapshot, original.medicationSnapshot) ||
          event.regimenId != original.regimenId ||
          event.regimenSnapshot != original.regimenSnapshot ||
          event.recordedAt.isBefore(original.recordedAt)) {
        throw StateError('Corrections must preserve original snapshots.');
      }
    }
    _administrations.add(event);
  }
}
