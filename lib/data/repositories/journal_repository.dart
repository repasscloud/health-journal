import '../../domain/medication.dart';

abstract interface class JournalRepository {
  List<Medication> get medications;
  List<Administration> get administrations;
  void saveMedication(Medication medication);
  void recordAdministration(Administration event);
}
