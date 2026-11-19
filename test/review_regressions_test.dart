import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/app/environment.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/regimen.dart';
import 'package:health_journal/features/medications/regimen_validation.dart';

void main() {
  test('course end is required and strictly after the start instant', () {
    final start = DateTime.utc(2020, 1, 1, 12);
    expect(validateCourseEnd(DateTime.utc(2020, 1, 2), start), isNull);
    expect(validateCourseEnd(null, start), isNotNull);
    expect(validateCourseEnd(DateTime.utc(2020, 1, 1), start), isNotNull);
    expect(validateCourseEnd(start, start), isNotNull);
  });
  test('out of range direct writes and corrections are atomic', () {
    final repo = DemoRepository();
    final med = repo.medications.single;
    final start = DateTime.utc(2020);
    final regimen = Regimen(
      id: 'r',
      medicationId: med.id,
      amount: 1,
      unit: 'tablet',
      kind: ScheduleKind.prn,
      effectiveFrom: start,
      effectiveTo: start.add(const Duration(days: 2)),
    );
    repo.addRegimen(regimen);
    final original = regimen.record(
      eventId: 'original',
      medication: med,
      status: AdministrationStatus.skipped,
      recordedAt: start.add(const Duration(days: 1)),
    );
    repo.recordAdministration(original);
    final before = [
      repo.medications,
      repo.medicationHistory,
      repo.regimens,
      repo.administrations,
      repo.symptoms,
      repo.measurements,
    ];
    for (final corrects in [null, original.id]) {
      for (final time in [
        start.subtract(const Duration(seconds: 1)),
        regimen.effectiveTo!,
      ]) {
        final event = Administration(
          id: 'bad',
          medicationId: med.id,
          medicationNameSnapshot: original.medicationNameSnapshot,
          medicationSnapshot: original.medicationSnapshot,
          regimenId: regimen.id,
          regimenSnapshot: original.regimenSnapshot,
          status: AdministrationStatus.skipped,
          occurredAt: time,
          recordedAt: DateTime.utc(2026),
          amount: 1,
          unit: 'tablet',
          correctsId: corrects,
          correctionReason: 'test',
        );
        expect(() => repo.recordAdministration(event), throwsStateError);
        expect([
          repo.medications,
          repo.medicationHistory,
          repo.regimens,
          repo.administrations,
          repo.symptoms,
          repo.measurements,
        ], before);
      }
    }
  });
  test(
    'review boots are fresh, rich, immutable and production stays gated',
    () {
      final a = AppEnvironment.fictionalReview();
      final b = AppEnvironment.fictionalReview();
      expect(a.isReview, isTrue);
      expect(
        a.repository!.regimens.map((r) => r.kind).toSet(),
        ScheduleKind.values.toSet(),
      );
      expect(
        a.repository!.administrations.where((e) => e.correctsId != null),
        hasLength(1),
      );
      expect(a.repository!.symptoms.single.pain.map((p) => p.view).toSet(), {
        'front',
        'back',
      });
      expect(a.repository!.measurements, hasLength(6));
      expect(a.repository!.medicationHistory, hasLength(1));
      expect(
        a.repository!
            .timeline()
            .where((i) => i.type == 'schedule')
            .any((i) => i.text.contains('catalogue revised')),
        isFalse,
      );
      expect(a.repository!.timeline(search: 'correction'), isNotEmpty);
      expect(() => a.repository!.medications.clear(), throwsUnsupportedError);
      expect(
        identical(
          a.repository!.medications.first,
          b.repository!.medications.first,
        ),
        isFalse,
      );
      expect(const AppEnvironment.nativePending().repository, isNull);
    },
  );
  test('build composition isolates review identity and entry point', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('kIsWeb'));
    expect(main, contains("if (dart.library.io) 'app/production_native.dart'"));
    expect(main, contains('AppEnvironment.demo()'));
    final production = File('lib/app/production_native.dart')
        .readAsStringSync();
    expect(production, contains('Platform.isAndroid'));
    expect(production, contains('AppEnvironment.nativePending()'));
    expect(main, isNot(contains('fictionalReview')));
    final review = File('lib/main_review.dart').readAsStringSync();
    expect(review, contains("appFlavor != 'review'"));
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.repasscloud.healthjournal"'));
    expect(gradle, contains('gradleProperty("healthJournalDeviceTest")'));
    expect(gradle, contains('applicationIdSuffix = ".devicetest"'));
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final reviewManifest = File('android/app/src/review/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:label="Health Journal"'));
    expect(manifest, isNot(contains('ReviewEntry')));
    expect(reviewManifest, contains('android:name=".ReviewEntry"'));
    final activity = File(
      'android/app/src/main/kotlin/com/repasscloud/healthjournal/MainActivity.kt',
    ).readAsStringSync();
    expect(
      activity.indexOf('if (BuildConfig.FLAVOR == "review") return'),
      lessThan(activity.indexOf('super.configureFlutterEngine')),
    );
    for (final path in [
      'lib/main_review.dart',
      'lib/app/environment.dart',
      'lib/data/demo/demo_repository.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(
          matches(
            r'import .*?(native_store|secure_storage|encrypted_database)',
          ),
        ),
      );
    }
  });
}
