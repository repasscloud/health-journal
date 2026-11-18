import '../../domain/regimen.dart';

String? validateCourseEnd(DateTime? end, DateTime effectiveStart) =>
    end == null || !end.isAfter(effectiveStart)
    ? 'Choose an end date after the effective start.'
    : null;

bool hasSharedWeekdays(List<ScheduleRule> rules) =>
    rules.isEmpty ||
    rules.every(
      (r) =>
          r.weekdays.length == rules.first.weekdays.length &&
          r.weekdays.containsAll(rules.first.weekdays),
    );
