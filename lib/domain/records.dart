import 'body_map.dart';

final class PainObservation {
  PainObservation({
    required this.id,
    required this.view,
    required this.x,
    required this.y,
    required this.severity,
    this.painType = 'aching',
    this.assetVersion = 'v1',
  }) {
    if (id.isEmpty ||
        !['front', 'back'].contains(view) ||
        assetVersion != 'v1' ||
        bodyRegionAt(x, y) == null ||
        severity < 0 ||
        severity > 10 ||
        ![
          'aching',
          'sharp',
          'burning',
          'throbbing',
          'tingling',
          'other',
        ].contains(painType)) {
      throw ArgumentError(
        'Choose a valid body location, pain type and severity.',
      );
    }
  }
  final String id, view, painType, assetVersion;
  final double x, y;
  final int severity;
  String get region => anatomicalRegion(bodyRegionAt(x, y)!, view);
  String get laterality => region.startsWith('left')
      ? 'left'
      : region.startsWith('right')
      ? 'right'
      : 'midline';
}

final class SymptomEntry {
  SymptomEntry({
    required this.id,
    required String title,
    required this.onsetAt,
    required this.recordedAt,
    this.endAt,
    this.severity,
    this.notes = '',
    List<PainObservation> pain = const [],
  }) : title = title.trim(),
       pain = List.unmodifiable(pain) {
    if (id.isEmpty ||
        this.title.isEmpty ||
        !onsetAt.isUtc ||
        !recordedAt.isUtc ||
        (endAt != null && (!endAt!.isUtc || endAt!.isBefore(onsetAt))) ||
        (severity != null && (severity! < 0 || severity! > 10)) ||
        pain.map((p) => p.id).toSet().length != pain.length) {
      throw ArgumentError('Enter a title, valid dates and severity.');
    }
  }
  final String id, title, notes;
  final DateTime onsetAt, recordedAt;
  final DateTime? endAt;
  final int? severity;
  final List<PainObservation> pain;
}

enum MeasurementKind {
  weight,
  bloodPressure,
  heartRate,
  temperature,
  glucose,
  sleep,
}

final class Measurement {
  Measurement({
    required this.id,
    required this.kind,
    required this.value,
    required this.unit,
    required this.measuredAt,
    required this.recordedAt,
    this.secondary,
  }) {
    if (id.isEmpty ||
        !value.isFinite ||
        value <= 0 ||
        !measuredAt.isUtc ||
        !recordedAt.isUtc ||
        unit != units[kind] ||
        (kind == MeasurementKind.bloodPressure
            ? secondary == null || !secondary!.isFinite || secondary! <= 0
            : secondary != null)) {
      throw ArgumentError(
        'Enter positive values in the indicated canonical units.',
      );
    }
  }
  static const units = {
    MeasurementKind.weight: 'kg',
    MeasurementKind.bloodPressure: 'mmHg',
    MeasurementKind.heartRate: 'bpm',
    MeasurementKind.temperature: '°C',
    MeasurementKind.glucose: 'mmol/L',
    MeasurementKind.sleep: 'hours',
  };
  final String id, unit;
  final MeasurementKind kind;
  final double value;
  final double? secondary;
  final DateTime measuredAt, recordedAt;
  String get source => 'manual';
  String get display =>
      '${kind.name}: $value${secondary == null ? '' : '/$secondary'} $unit';
}

final class TimelineItem {
  const TimelineItem(this.id, this.at, this.type, this.text);
  final String id, type, text;
  final DateTime at;
}
