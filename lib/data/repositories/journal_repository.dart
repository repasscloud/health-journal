import '../../domain/medication.dart';
import '../../domain/regimen.dart';
import '../../domain/records.dart';

abstract interface class JournalRepository {
  List<SymptomEntry> get symptoms;
  List<Measurement> get measurements;
  void addSymptom(SymptomEntry symptom);
  void addMeasurement(Measurement measurement);
  List<TimelineItem> timeline({String search = ''});
  List<Medication> get medications;
  List<Regimen> get regimens;
  void addRegimen(Regimen regimen);
  void reviseRegimen(String previousId, Regimen revision);
  List<Administration> get administrations;
  void saveMedication(Medication medication);
  void recordAdministration(Administration event);
}
