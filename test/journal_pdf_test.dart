import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/domain/records.dart';
import 'package:health_journal/features/reports/journal_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final end = DateTime.utc(2026, 11, 20, 14);
  final hasPoppler =
      File('/usr/bin/pdftotext').existsSync() ||
      (Platform.environment['PATH'] ?? '')
          .split(Platform.isWindows ? ';' : ':')
          .any((path) => File('$path/pdftotext').existsSync());

  test('empty journal generates one valid report page', () async {
    final bytes = await journalPdf(DemoRepository(), generatedAt: end);
    final content = String.fromCharCodes(bytes);
    expect(content, startsWith('%PDF-'));
    expect(content, contains('/Count 1'));
  });

  test(
    'report covers the UTC window and renders versioned revisions across pages',
    () async {
      final repo = DemoRepository(richFixture: true);
      final start = DateTime.utc(2026, 10, 22);
      final longNote = List.filled(
        180,
        'Long-note example août München',
      ).join('\n');
      for (final (id, title, onset) in [
        ('boundary', 'Included boundary entry', start),
        (
          'old',
          'Excluded old entry',
          start.subtract(const Duration(seconds: 1)),
        ),
        (
          'future',
          'Excluded future entry',
          end.add(const Duration(seconds: 1)),
        ),
      ]) {
        repo.addSymptom(
          SymptomEntry(
            id: id,
            title: title,
            onsetAt: onset,
            endAt: onset,
            recordedAt: onset,
            notes: id == 'boundary' ? '$longNote\nEnd of long note' : '',
          ),
        );
      }
      final original = repo.symptoms.singleWhere(
        (item) => item.id == 'review-symptom',
      );
      repo.reviseSymptom(
        SymptomEntry(
          id: original.id,
          title: 'Fictional revised symptom',
          onsetAt: original.onsetAt,
          recordedAt: original.recordedAt,
          updatedAt: end,
          pain: [
            PainObservation(
              id: 'v2-fixture',
              view: 'back',
              x: .57,
              y: .32,
              assetVersion: 'v2',
              radius: .07,
              severity: 8,
              painType: 'sharp',
            ),
          ],
        ),
      );
      final bytes = await journalPdf(repo, generatedAt: end);
      final raw = String.fromCharCodes(bytes);
      expect(raw, startsWith('%PDF-'));
      expect(RegExp(r'/Type\s*/Page\b').allMatches(raw).length, greaterThan(3));

      if (hasPoppler) {
        final folder = Directory.systemTemp.createTempSync('fictional_pdf_');
        addTearDown(() => folder.deleteSync(recursive: true));
        final pdf = File('${folder.path}/report.pdf')..writeAsBytesSync(bytes);
        final result = await Process.run('pdftotext', [
          '-layout',
          pdf.path,
          '-',
        ]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
        final report = result.stdout as String;
        for (final expected in [
          '2026-10-22 through 2026-11-20',
          'Included boundary entry',
          'Fictional revised symptom',
          'front · v1',
          'back · v2',
          'Area radius 7.0%',
          'sharp · 8/10',
          'previous revision',
          'corrects review-event-fixed',
          'superseded',
          'Dated timeline',
          'End of long note',
          'août München',
          'Page 1 of',
        ]) {
          expect(report, contains(expected));
        }
        expect(report, isNot(contains('Excluded old entry')));
        expect(report, isNot(contains('Excluded future entry')));
        final raster = await Process.run('pdftoppm', [
          '-f',
          '2',
          '-l',
          '2',
          '-r',
          '72',
          '-png',
          '-singlefile',
          pdf.path,
          '${folder.path}/map',
        ]);
        expect(raster.exitCode, 0, reason: '${raster.stderr}');
        final codec = await ui.instantiateImageCodec(
          File('${folder.path}/map.png').readAsBytesSync(),
        );
        final image = (await codec.getNextFrame()).image;
        final pixels = (await image.toByteData())!;
        List<(int, int)> markerPixels(int startY, int endY) => [
          for (var y = startY; y <= endY; y++)
            for (var x = 160; x <= 194; x++)
              if (pixels.getUint8(4 * (y * image.width + x)) > 120 &&
                  pixels.getUint8(4 * (y * image.width + x) + 1) < 80 &&
                  pixels.getUint8(4 * (y * image.width + x) + 2) < 80)
                (x, y),
        ];
        // Raster geometry on the versioned silhouettes, at 1 px per PDF point.
        // The saved 7% radius is visibly wider than the v1 point glyph.
        final v2 = markerPixels(240, 272);
        final v1 = markerPixels(495, 525);
        int span(List<(int, int)> points) => points.last.$1 - points.first.$1;
        expect(v2, isNotEmpty);
        v2.sort((a, b) => a.$1.compareTo(b.$1));
        v1.sort((a, b) => a.$1.compareTo(b.$1));
        expect(span(v2), greaterThan(span(v1) + 4));
        expect(v1.length, greaterThan(5));
        for (final (pixels, x, y) in [(v2, 183.3, 256), (v1, 177.0, 511)]) {
          expect(
            pixels.map((p) => p.$1).reduce((a, b) => a + b) / pixels.length,
            closeTo(x, 1),
          );
          expect(
            pixels.map((p) => p.$2).reduce((a, b) => a + b) / pixels.length,
            closeTo(y, 1),
          );
        }
        image.dispose();
        codec.dispose();
        final inspectPath = Platform.environment['HJ_FICTIONAL_REPORT_OUTPUT'];
        if (inspectPath != null) pdf.copySync(inspectPath);
      }
    },
  );
}
