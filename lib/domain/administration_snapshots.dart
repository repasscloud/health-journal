import 'dart:convert';

import 'medication.dart';
import 'regimen.dart';

/// Versioned values, independent of mutable catalogue and schedule rows.
/// A change to the persisted fields or meaning requires a new version.
abstract final class AdministrationSnapshots {
  static String catalogue(Medication value) => jsonEncode({
    'version': 1,
    'id': value.id,
    'name': value.name,
    'strength': value.strength,
    'createdAt': value.createdAt.toIso8601String(),
    'updatedAt': value.updatedAt.toIso8601String(),
    'archived': value.archived,
    'genericName': value.genericName,
    'brand': value.brand,
    'form': value.form,
    'strengthUnit': value.strengthUnit,
    'instructions': value.instructions,
    'reason': value.reason,
    'prescribedBy': value.prescribedBy,
    'notes': value.notes,
    'startedAt': value.startedAt?.toIso8601String(),
    'stoppedAt': value.stoppedAt?.toIso8601String(),
    'pausedAt': value.pausedAt?.toIso8601String(),
  });

  static String schedule(Regimen value) => jsonEncode({
    'version': 1,
    'id': value.id,
    'medicationId': value.medicationId,
    'amount': value.amount,
    'unit': value.unit,
    'kind': value.kind.name,
    'effectiveFrom': value.effectiveFrom.toIso8601String(),
    'effectiveTo': value.effectiveTo?.toIso8601String(),
    'instructions': value.instructions,
    'zonePolicy': value.zonePolicy,
    'rules': [
      for (final rule in value.rules)
        {
          'hour': rule.hour,
          'minute': rule.minute,
          'weekdays': rule.weekdays.toList()..sort(),
        },
    ],
  });

  static Map<String, dynamic> _read(String source) {
    final data = jsonDecode(source);
    if (data is! Map<String, dynamic> || data['version'] != 1) {
      throw const FormatException('Unsupported administration snapshot.');
    }
    return data;
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  static Medication readCatalogue(String source) {
    final data = _read(source);
    return Medication(
      id: data['id'] as String,
      name: data['name'] as String,
      strength: data['strength'] as String,
      createdAt: _date(data['createdAt'])!,
      updatedAt: _date(data['updatedAt'])!,
      archived: data['archived'] as bool,
      genericName: data['genericName'] as String,
      brand: data['brand'] as String,
      form: data['form'] as String,
      strengthUnit: data['strengthUnit'] as String,
      instructions: data['instructions'] as String,
      reason: data['reason'] as String,
      prescribedBy: data['prescribedBy'] as String,
      notes: data['notes'] as String,
      startedAt: _date(data['startedAt']),
      stoppedAt: _date(data['stoppedAt']),
      pausedAt: _date(data['pausedAt']),
    );
  }

  static Regimen readSchedule(String source) {
    final data = _read(source);
    if (data['zonePolicy'] != 'deviceLocal') {
      throw const FormatException('Unsupported snapshot time policy.');
    }
    return Regimen(
      id: data['id'] as String,
      medicationId: data['medicationId'] as String,
      amount: (data['amount'] as num).toDouble(),
      unit: data['unit'] as String,
      kind: ScheduleKind.values.byName(data['kind'] as String),
      effectiveFrom: _date(data['effectiveFrom'])!,
      effectiveTo: _date(data['effectiveTo']),
      instructions: data['instructions'] as String,
      rules: [
        for (final rule in data['rules'] as List)
          ScheduleRule(
            hour: rule['hour'] as int,
            minute: rule['minute'] as int,
            weekdays: (rule['weekdays'] as List).cast<int>().toSet(),
          ),
      ],
    );
  }
}
