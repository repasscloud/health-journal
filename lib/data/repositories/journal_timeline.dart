import '../../domain/medication.dart';
import '../../domain/records.dart';
import '../../domain/regimen.dart';

List<TimelineItem> journalTimeline({
  required List<Administration> administrations,
  required List<Regimen> regimens,
  required String Function(Regimen) regimenName,
  required List<SymptomEntry> symptoms,
  required List<Measurement> measurements,
  required String search,
}) {
  final correctedIds = administrations.map((event) => event.correctsId).toSet();
  final items =
      [
            for (final e in administrations)
              TimelineItem(
                e.id,
                e.occurredAt,
                'medication',
                '${e.medicationNameSnapshot} • ${e.status.name} • ${e.amount} ${e.unit}${correctedIds.contains(e.id) ? ' • superseded' : ''}${e.correctsId != null ? ' • correction' : ''}',
              ),
            for (final r in regimens)
              TimelineItem(
                r.id,
                r.effectiveFrom,
                'schedule',
                '${regimenName(r)} • ${r.kind.name} • ${r.amount} ${r.unit} • unconfirmed',
              ),
            for (final s in symptoms)
              TimelineItem(
                s.id,
                s.onsetAt,
                'symptom',
                '${s.title} • ${s.notes} • ${s.category} • ${s.triggers} • ${s.relief} • ${s.effect} • ${s.pain.map((p) => '${p.view} ${p.region} ${p.severity}/10').join(', ')}',
              ),
            for (final m in measurements)
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
