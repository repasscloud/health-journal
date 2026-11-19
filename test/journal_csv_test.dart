import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/records.dart';
import 'package:health_journal/features/reports/journal_csv.dart';

void main() {
  test(
    'CSV retains canonical values, marker versions and revision provenance',
    () {
      final repository = DemoRepository(richFixture: true);
      final medication = repository.medications.first;
      final now = DateTime.utc(2026, 11, 19);
      repository.recordAdministration(
        Administration(
          id: 'fixture-dose',
          medicationId: medication.id,
          medicationNameSnapshot: medication.name,
          status: AdministrationStatus.skipped,
          recordedAt: now,
          occurredAt: now,
          amount: 1,
          unit: 'tablet',
          originalZoneLabel: 'Australia/Adelaide',
          originalOffsetMinutes: 630,
        ),
      );
      repository.addSymptom(
        SymptomEntry(
          id: 'fixture-symptom',
          title: 'Fictional "label", with comma',
          onsetAt: now,
          recordedAt: now,
          notes: '  =SUM(1,2)\nFictional text',
        ),
      );
      final csv = utf8.decode(journalCsv(repository));
      expect(csv, startsWith('"record_type","id","related_id","occurred_utc"'));
      expect(csv, contains('"Fictional ""label"", with comma"'));
      expect(csv, contains('''"'  =SUM(1,2)\nFictional text"'''));
      expect(csv, contains('"administration_correction","review-correction"'));
      expect(csv, contains('"Australia/Adelaide","630"'));
      expect(csv, contains('"pain_marker","review-front","review-symptom"'));
      expect(csv, contains('"v1","front","0.5","0.3"'));
      expect(csv, contains('"weight","manual","72.0","","kg"'));
      expect(csv, endsWith('\r\n'));
    },
  );
}
