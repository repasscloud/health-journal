import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/repositories/journal_repository.dart';
import '../../domain/records.dart';

/// The report includes the current UTC calendar date and the 29 preceding
/// dates. Events dated after generation are excluded.
Future<Uint8List> journalPdf(
  JournalRepository repository, {
  required DateTime generatedAt,
  AssetBundle? assets,
}) async {
  final end = generatedAt.toUtc();
  final start = DateTime.utc(end.year, end.month, end.day - 29);
  bool within(DateTime at) => !at.isBefore(start) && !at.isAfter(end);

  // Capture one consistent view of the journal before loading any assets.
  final timeline = repository
      .timeline()
      .where((item) => within(item.at))
      .toList();
  final symptoms = [
    for (final item in repository.symptoms)
      if (within(item.onsetAt) ||
          within(item.updatedAt) ||
          (item.onsetAt.isBefore(start) &&
              (item.endAt != null && !item.endAt!.isBefore(start))))
        item,
  ];
  final previousSymptoms = {
    for (final item in symptoms) item.id: repository.symptomHistory(item.id),
  };
  final doses = repository.administrations
      .where((item) => within(item.occurredAt))
      .toList();
  final corrected = repository.administrations
      .map((item) => item.correctsId)
      .toSet();
  final regimens = repository.regimens
      .where(
        (item) =>
            !item.effectiveFrom.isAfter(end) &&
            (item.effectiveTo == null || item.effectiveTo!.isAfter(start)),
      )
      .toList();
  final catalogue = {for (final item in repository.medications) item.id: item};
  final listedMedications = {
    ...regimens.map((item) => item.medicationId),
    ...doses.map((item) => item.medicationId),
  };
  final symptomTitles = {for (final item in symptoms) item.id: item.title};
  final measurements = {
    for (final item in repository.measurements) item.id: item,
  };
  final bundle = assets ?? rootBundle;
  final font = pw.Font.ttf(
    await bundle.load('assets/report/Roboto-Regular.ttf'),
  );
  final maps = <(String, String), String>{};
  for (final item in symptoms) {
    for (final revision in [item, ...previousSymptoms[item.id]!]) {
      for (final point in revision.pain) {
        final key = (point.assetVersion, point.view);
        if (!maps.containsKey(key)) {
          maps[key] = await bundle.loadString(
            'assets/bodymaps/${point.assetVersion}/${point.view}.svg',
          );
        }
      }
    }
  }
  final body = <pw.Widget>[];
  void paragraph(String text) {
    if (text.isEmpty) return;
    // Keep each flow item shorter than a page, including free-form notes.
    for (final match in RegExp(
      r'.{1,240}(?:\s|$)|.{1,240}',
      dotAll: true,
      unicode: true,
    ).allMatches(text)) {
      body.add(
        pw.Text(
          match.group(0)!,
          overflow: pw.TextOverflow.clip,
          hyphenation: _wordParts,
        ),
      );
    }
    body.add(pw.SizedBox(height: 5));
  }

  void section(String title) {
    body.add(pw.NewPage(freeSpace: 65));
    body.add(pw.Header(level: 1, text: title));
  }

  String stamp(DateTime at) =>
      '${at.toUtc().toIso8601String().substring(0, 16).replaceFirst('T', ' ')} UTC';
  String date(DateTime at) => at.toIso8601String().split('T').first;

  paragraph('${date(start)} through ${date(end)} (UTC)');
  paragraph(
    'Generated ${stamp(end)} from this local journal. Entries reflect self-reported observations. Regimens describe plans. Only explicitly recorded intake is shown as taken.',
  );

  section('Medications');
  if (regimens.isEmpty && doses.isEmpty) {
    paragraph('No structured regimens or administrations in this period.');
  }
  for (final id in listedMedications) {
    final medication = catalogue[id];
    if (medication == null) continue;
    paragraph(
      [
        '${medication.name} · catalogue${medication.archived ? ' · archived' : ''}',
        [
          medication.form,
          medication.strength,
          medication.strengthUnit,
        ].where((text) => text.isNotEmpty).join(' '),
      ].where((text) => text.isNotEmpty).join('\n'),
    );
  }
  for (final plan in regimens) {
    paragraph(
      '${catalogue[plan.medicationId]?.name ?? plan.medicationId} — plan ${plan.id}\n'
      '${plan.amount} ${plan.unit} · ${plan.kind.name} · from ${stamp(plan.effectiveFrom)}'
      '${plan.effectiveTo == null ? '' : ' until ${stamp(plan.effectiveTo!)}'}\n'
      '${plan.rules.map((rule) => '${rule.localTime} (weekdays ${(rule.weekdays.toList()..sort()).join(", ")})').join("; ")}'
      '${plan.rules.isEmpty ? '' : ' · device local · weekdays 1 = Monday'}\n'
      '${plan.instructions}',
    );
  }
  for (final dose in doses) {
    paragraph(
      '${stamp(dose.occurredAt)} · ${dose.medicationNameSnapshot} · ${dose.status.name} · ${dose.amount} ${dose.unit}\n'
      'Recorded ${stamp(dose.recordedAt)} · entry ${dose.id}'
      '${corrected.contains(dose.id) ? ' · superseded' : ''}'
      '${dose.correctsId == null ? '' : ' · corrects ${dose.correctsId}: ${dose.correctionReason}'}\n'
      '${dose.originalZoneLabel == null ? 'Original time zone unavailable' : '${dose.originalZoneLabel} · UTC offset ${dose.originalOffsetMinutes} min'}'
      '${dose.intendedAt == null ? '' : '\nScheduled ${stamp(dose.intendedAt!)} · slot ${dose.occurrenceKey}'}'
      '${dose.regimenId == null ? '' : '\nRegimen ${dose.regimenId}'}\n'
      '${dose.notes}',
    );
  }

  section('Symptoms and pain maps');
  paragraph(
    'Map labels indicate anatomical left and right. A circle marks the saved point or area. Severity uses a 0–10 scale.',
  );
  if (symptoms.isEmpty) paragraph('No symptoms in this period.');
  for (final symptom in symptoms) {
    for (final (index, item) in [
      symptom,
      ...previousSymptoms[symptom.id]!,
    ].indexed) {
      paragraph(
        '${item.title} · ${index == 0 ? 'current' : 'previous revision'} · entry ${item.id}\n'
        'Onset ${stamp(item.onsetAt)}'
        '${item.endAt == null ? '' : ' · ended ${stamp(item.endAt!)}'}\n'
        'Recorded ${stamp(item.recordedAt)} · revision ${stamp(item.updatedAt)}'
        '${item.severity == null ? '' : ' · severity ${item.severity}/10'}',
      );
      for (final (label, value) in [
        ('Category', item.category),
        ('Pattern', item.pattern ?? ''),
        ('Triggers', item.triggers),
        ('Relief', item.relief),
        ('Perceived effect', item.effect),
        ('Notes', item.notes),
      ]) {
        if (value.isNotEmpty) paragraph('$label — $value');
      }
      for (final point in item.pain) {
        body.add(_painMap(point, maps[(point.assetVersion, point.view)]!));
      }
    }
  }

  section('Dated timeline');
  if (timeline.isEmpty) paragraph('No timeline entries in this period.');
  for (final item in timeline) {
    final measurement = item.type == 'measurement'
        ? measurements[item.id]
        : null;
    final description = item.type == 'symptom'
        ? symptomTitles[item.id] ?? item.text
        : measurement == null
        ? item.text
        : '${measurement.display} · ${measurement.source} · recorded ${stamp(measurement.recordedAt)}';
    paragraph('${stamp(item.at)} · ${item.type} · $description');
  }

  final pdf = pw.Document(title: 'Health Journal — 30-day report');
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: font),
      maxPages: body.length + 1,
      margin: const pw.EdgeInsets.all(42),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          'Health Journal · 30-day report',
          style: const pw.TextStyle(fontSize: 16),
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
      ),
      build: (_) => body,
    ),
  );
  return pdf.save();
}

List<String> _wordParts(String word) => word.runes.length <= 32
    ? [word]
    : RegExp(
        r'.{1,4}',
        unicode: true,
      ).allMatches(word).map((match) => match.group(0)!).toList();

pw.Widget _painMap(PainObservation point, String svg) {
  const width = 90.0;
  const height = width * 2;
  final radius = width * (point.radius ?? .035);
  final isFront = point.view == 'front';
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: width * 3,
          height: height,
          child: pw.Stack(
            children: [
              pw.Positioned(
                left: width,
                top: 0,
                child: pw.SvgImage(svg: svg, width: width, height: height),
              ),
              pw.Positioned(
                left: width + point.x * width - radius,
                top: point.y * height - radius,
                child: pw.Container(
                  width: 2 * radius,
                  height: 2 * radius,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.red900, width: 1.4),
                  ),
                ),
              ),
              pw.Positioned(
                left: width - 12,
                top: 2,
                child: pw.Text(isFront ? 'R' : 'L'),
              ),
              pw.Positioned(
                left: 2 * width + 5,
                top: 2,
                child: pw.Text(isFront ? 'L' : 'R'),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            '${point.view} · ${point.assetVersion}\n'
            '${point.region} · ${point.painType} · ${point.severity}/10\n'
            '${point.radius == null ? 'Point' : 'Area radius ${(point.radius! * 100).toStringAsFixed(1)}% of map width'}',
          ),
        ),
      ],
    ),
  );
}
