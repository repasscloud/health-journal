import '../../domain/medication.dart';
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
  final List<Medication> _medications = [];
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
    _administrations.add(event);
  }
}
