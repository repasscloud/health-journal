import 'package:flutter/material.dart';

import '../domain/medication.dart';
import '../domain/regimen.dart';

extension AdministrationStatusLabel on AdministrationStatus {
  String get label => switch (this) {
    AdministrationStatus.taken => 'Taken',
    AdministrationStatus.skipped => 'Skipped',
    AdministrationStatus.missed => 'Missed',
    AdministrationStatus.unknown => 'Unconfirmed',
  };
}

extension ScheduleKindLabel on ScheduleKind {
  String get label => switch (this) {
    ScheduleKind.fixed => 'Scheduled',
    ScheduleKind.course => 'Course',
    ScheduleKind.prn => 'As needed',
  };
}

String journalDateTime(BuildContext context, DateTime time) {
  final local = time.toLocal();
  final date = MaterialLocalizations.of(context).formatShortDate(local);
  final clock = TimeOfDay.fromDateTime(local).format(context);
  return '$date at $clock';
}

String journalQuantity(double value) =>
    value.toString().replaceFirst(RegExp(r'\.0$'), '');

String journalLabel(String value) => value
    .split(RegExp(r'[_ ]+'))
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
