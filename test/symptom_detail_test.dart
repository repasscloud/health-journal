import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/app/environment.dart';
import 'package:health_journal/app/journal_app.dart';
import 'package:health_journal/domain/records.dart';
import 'package:health_journal/features/records/symptom_detail.dart';

void main() {
  final at = DateTime.utc(2026, 11, 15);
  final entry = SymptomEntry(
    id: 'detail-test',
    title: 'Fictional map history',
    onsetAt: at,
    recordedAt: at,
    notes: 'Fictional observation notes',
    pain: [
      for (final version in ['v1', 'v2'])
        for (final view in ['front', 'back'])
          PainObservation(
            id: '$version-$view',
            view: view,
            assetVersion: version,
            x: version == 'v1' ? .23 : .15,
            y: version == 'v1' ? .44 : .575,
            severity: view == 'front' ? 4 : 7,
            painType: 'sharp',
          ),
    ],
  );

  testWidgets('Timeline opens read-only symptom details', (tester) async {
    final env = AppEnvironment.demo(richFixture: false);
    env.repository!.addSymptom(entry);
    await tester.pumpWidget(JournalApp(environment: env));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    final details = find.text('View symptom details');
    final list = find.ancestor(of: details, matching: find.byType(ListView));
    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(find.byType(SymptomDetail), findsOneWidget);
    expect(find.text('Fictional map history'), findsOneWidget);
    expect(find.text('Fictional observation notes'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      find.textContaining('Changes reset when you reload'),
      findsOneWidget,
    );
  });

  testWidgets('each map uses its saved asset, position and accessible label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [215.0, 520.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(width),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: SymptomDetail(entry: entry),
        ),
      );
      await tester.pumpAndSettle();
      for (final (index, point) in entry.pain.indexed) {
        final map = find.byKey(ValueKey('saved-map-${point.id}'));
        await tester.scrollUntilVisible(map, 180);
        final svg = tester.widget<SvgPicture>(map);
        expect(
          (svg.bytesLoader as SvgAssetLoader).assetName,
          'assets/bodymaps/${point.assetVersion}/${point.view}.svg',
        );
        final rect = tester.getRect(map);
        expect(rect.height, closeTo(rect.width * 2, .01));
        if (width == 215) {
          expect(rect.width, lessThan(180));
        } else {
          expect(rect.width, 180);
        }
        final marker = tester.getCenter(
          find.byKey(ValueKey('saved-marker-${point.id}')),
        );
        expect(marker.dx, closeTo(rect.left + point.x * rect.width, .01));
        expect(marker.dy, closeTo(rect.top + point.y * rect.height, .01));
        final side = point.view == 'front' ? 'Right' : 'Left';
        final label = find.bySemanticsLabel(
          'Marker ${index + 1}, ${point.view == 'front' ? 'Front' : 'Back'} view, '
          '$side Arm, Sharp, severity ${point.severity} out of 10',
        );
        final legend = find.text(
          '${index + 1}. $side Arm · Sharp · ${point.severity}/10',
        );
        await tester.scrollUntilVisible(legend, 100);
        await tester.pumpAndSettle();
        expect(label, findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });
}
