import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/domain/body_map.dart';
import 'package:health_journal/domain/body_map_v2.dart';
import 'package:health_journal/domain/records.dart';
import 'package:health_journal/data/demo/demo_repository.dart';

void main() {
  test('versioned SVG polygons and silhouette geometry match exactly', () {
    for (final view in ['front', 'back']) {
      final svg = File('assets/bodymaps/v1/$view.svg').readAsStringSync();
      expect(svg, contains('viewBox="0 0 100 200"'));
      for (final r in bodyRegionsV1) {
        final points = r.points
            .map((p) => '${p.$1.toInt()},${p.$2.toInt()}')
            .join(' ');
        expect(svg, contains('id="${r.code}" points="$points"'));
        expect(bodyRegionAt(r.center.$1, r.center.$2), r);
      }
    }
    expect(bodyRegionAt(0, 0), isNull);
    expect(bodyRegionAt(.5, .9), isNull); // gap between legs
    expect(bodyRegionAt(double.nan, .5), isNull);
    expect(bodyRegionAt(1.1, .5), isNull);
  });
  test('v2 hit testing matches the SVG outlines and region anchors', () {
    String normalize(String path) =>
        path.trim().replaceAll(RegExp(r'\s+'), ' ');
    for (final view in ['front', 'back']) {
      final svg = File('assets/bodymaps/v2/$view.svg').readAsStringSync();
      final svgPath = RegExp(r'id="silhouette"[^>]+ d="([^"]+)"')
          .firstMatch(svg)!
          .group(1)!;
      expect(normalize(bodySilhouetteV2(view)), normalize(svgPath));
      for (final region in bodyRegionsV2) {
        final (x, y) = region.center;
        expect(bodyRegionAt(x, y, version: 'v2', view: view), region);
      }
      expect(bodyRegionAt(.5, .9, version: 'v2', view: view), isNull);
      expect(bodyRegionAt(.3, .42, version: 'v2', view: view), isNull);
      final hand = PainObservation(
        id: 'hand',
        view: view,
        x: .15,
        y: .575,
        severity: 2,
        assetVersion: 'v2',
      );
      expect(hand.region, view == 'front' ? 'right_arm' : 'left_arm');
      expect(bodyRegionAt(hand.x, hand.y), isNull);
    }

    // The toe extends beyond the heel in the front view.
    expect(
      bodyRegionAt(.69, .972, version: 'v2', view: 'front')?.code,
      'viewer_right_leg',
    );
    expect(bodyRegionAt(.69, .972, version: 'v2', view: 'back'), isNull);
  });
  test('front/back laterality is anatomical and coordinates are independent of layout', () {
    final region = bodyRegionsV1.firstWhere((r) => r.code == 'viewer_left_arm');
    for (final width in [100.0, 200.0, 560.0]) {
      final point = region.center;
      final pixelX = point.$1 * width;
      final pixelY = point.$2 * width * 2;
      expect(bodyRegionAt(pixelX / width, pixelY / (width * 2)), region);
    }
    expect(anatomicalRegion(region, 'front'), 'right_arm');
    expect(anatomicalRegion(region, 'back'), 'left_arm');
  });
  test(
    'multiple observations retain individual severity, view and asset revision',
    () {
      final now = DateTime.utc(2026, 11, 17);
      final input = [
        PainObservation(id: 'p1', view: 'front', x: .5, y: .3, severity: 3),
        PainObservation(
          id: 'p2',
          view: 'back',
          x: .5,
          y: .3,
          severity: 7,
          painType: 'sharp',
          assetVersion: 'v2',
        ),
      ];
      final symptom = SymptomEntry(
        id: 's',
        title: 'Fictional symptom',
        onsetAt: now,
        recordedAt: now,
        pain: input,
      );
      input.clear();
      expect(symptom.pain.length, 2);
      expect(symptom.pain.last.severity, 7);
      expect(symptom.pain.first.assetVersion, 'v1');
      expect(symptom.pain.last.assetVersion, 'v2');
      expect(
        () => PainObservation(id: 'p', view: 'front', x: 0, y: 0, severity: 2),
        throwsArgumentError,
      );
    },
  );
  test(
    'manual measurements validate units, paired BP and searchable timeline',
    () {
      final now = DateTime.utc(2026, 11, 17);
      final repository = DemoRepository();
      final measurement = Measurement(
        id: 'm',
        kind: MeasurementKind.bloodPressure,
        value: 120,
        secondary: 80,
        unit: 'mmHg',
        measuredAt: now,
        recordedAt: now,
      );
      repository.addMeasurement(measurement);
      expect(
        repository.timeline(search: '120/80'),
        isEmpty,
      ); // decimal canonical representation
      expect(
        repository.timeline(search: 'bloodPressure').single.text,
        contains('manual'),
      );
      expect(() => repository.addMeasurement(measurement), throwsStateError);
      expect(
        () => Measurement(
          id: 'bad',
          kind: MeasurementKind.bloodPressure,
          value: 120,
          unit: 'mmHg',
          measuredAt: now,
          recordedAt: now,
        ),
        throwsArgumentError,
      );
      expect(
        () => Measurement(
          id: 'bad',
          kind: MeasurementKind.weight,
          value: double.infinity,
          unit: 'kg',
          measuredAt: now,
          recordedAt: now,
        ),
        throwsArgumentError,
      );
      expect(
        () => Measurement(
          id: 'bad',
          kind: MeasurementKind.glucose,
          value: 5,
          unit: 'mg/dL',
          measuredAt: now,
          recordedAt: now,
        ),
        throwsArgumentError,
      );
      expect(DemoRepository().measurements, isEmpty);
    },
  );
}
