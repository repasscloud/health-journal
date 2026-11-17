import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/domain/medication.dart';

void main() {
  test('separate boots and tabs cannot share mutable data', () {
    final first = DemoRepository();
    final second = DemoRepository();
    first.saveMedication(
      Medication(
        id: 'new',
        name: 'Sample',
        strength: '',
        createdAt: DateTime.utc(2026),
      ),
    );
    expect(first.medications.length, 2);
    expect(second.medications.length, 1);
    expect(() => first.medications.clear(), throwsUnsupportedError);
  });
  test('a planned medication never creates an administration', () {
    expect(DemoRepository().administrations, isEmpty);
  });
  test('taken state requires explicit intake timestamp', () {
    expect(
      () => Administration(
        id: 'a',
        medicationId: 'm',
        medicationNameSnapshot: 'Sample',
        status: AdministrationStatus.taken,
        recordedAt: DateTime.utc(2026),
        amount: 1,
        unit: 'tablet',
      ),
      throwsArgumentError,
    );
  });
  test('invalid medication names are rejected', () {
    expect(
      () => Medication(
        id: 'a',
        name: '  ',
        strength: '',
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
  });
}
