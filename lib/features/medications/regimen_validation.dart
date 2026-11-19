String? validateCourseEnd(DateTime? end, DateTime effectiveStart) =>
    end == null || !end.isAfter(effectiveStart)
    ? 'Choose an end date after the effective start.'
    : null;
