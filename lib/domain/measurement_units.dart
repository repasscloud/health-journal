import 'records.dart';

enum DisplayUnit {
  kilograms('kg'),
  pounds('lb'),
  celsius('°C'),
  fahrenheit('°F'),
  mmolPerLiter('mmol/L'),
  mgPerDeciliter('mg/dL');

  const DisplayUnit(this.symbol);
  final String symbol;

  double fromCanonical(double value) => switch (this) {
    pounds => value / 0.45359237,
    fahrenheit => value * 9 / 5 + 32,
    mgPerDeciliter => value * 18.01559,
    _ => value,
  };

  double toCanonical(double value) => switch (this) {
    pounds => value * 0.45359237,
    fahrenheit => (value - 32) * 5 / 9,
    mgPerDeciliter => value / 18.01559,
    _ => value,
  };
}

final class MeasurementUnits {
  const MeasurementUnits({
    this.weight = DisplayUnit.kilograms,
    this.temperature = DisplayUnit.celsius,
    this.glucose = DisplayUnit.mmolPerLiter,
  });

  final DisplayUnit weight, temperature, glucose;

  DisplayUnit? preference(MeasurementKind kind) => switch (kind) {
    MeasurementKind.weight => weight,
    MeasurementKind.temperature => temperature,
    MeasurementKind.glucose => glucose,
    _ => null,
  };

  String symbol(MeasurementKind kind) =>
      preference(kind)?.symbol ?? Measurement.units[kind]!;

  double toCanonical(MeasurementKind kind, double value) =>
      preference(kind)?.toCanonical(value) ?? value;

  String describe(Measurement measurement) {
    final kind = measurement.kind;
    final value =
        preference(kind)?.fromCanonical(measurement.value) ?? measurement.value;
    final quantity = symbol(kind) == measurement.unit || !value.isFinite
        ? value.toString()
        : value.toStringAsFixed(2);
    final reading = quantity.contains('.') && !quantity.contains('e')
        ? quantity.replaceFirst(RegExp(r'\.?0+$'), '')
        : quantity;
    final secondary = measurement.secondary;
    final pair = secondary == null
        ? ''
        : '/${secondary.toString().replaceFirst(RegExp(r'\.0$'), '')}';
    return '${kind.label} · $reading$pair ${symbol(kind)}';
  }
}
