import 'dart:async';

import '../../domain/medication.dart';
import '../../domain/measurement_units.dart';
import '../../domain/regimen.dart';
import '../../domain/records.dart';

abstract interface class JournalRepository {
  JournalPreferences get preferences;
  FutureOr<void> savePreferences(JournalPreferences preferences);
  List<SymptomEntry> get symptoms;
  List<Measurement> get measurements;
  FutureOr<void> addSymptom(SymptomEntry symptom);
  FutureOr<void> reviseSymptom(SymptomEntry symptom);
  List<SymptomEntry> symptomHistory(String id);
  FutureOr<void> addMeasurement(Measurement measurement);
  List<TimelineItem> timeline({String search = ''});
  List<Medication> get medications;
  List<Medication> get medicationHistory;
  List<Regimen> get regimens;
  FutureOr<void> addRegimen(Regimen regimen);
  FutureOr<void> reviseRegimen(String previousId, Regimen revision);
  List<Administration> get administrations;
  FutureOr<void> saveMedication(Medication medication);
  FutureOr<void> recordAdministration(Administration event);
}
