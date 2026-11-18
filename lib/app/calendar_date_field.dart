import 'package:flutter/material.dart';

class CalendarDateField extends StatelessWidget {
  const CalendarDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.canClear = false,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final FormFieldValidator<DateTime>? validator;
  final bool canClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
    initialValue: value,
    validator: validator,
    enabled: enabled,
    builder: (field) {
      final date = field.value?.toLocal();
      final initial = date ?? DateTime.now();
      void select(DateTime? next) {
        field.didChange(next);
        onChanged(next);
      }

      return InkWell(
        onTap: enabled
            ? () async {
                final selected = await showDatePicker(
                  context: field.context,
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  helpText: label,
                  initialDate: initial,
                  firstDate: DateTime(
                    initial.year < 1900 ? initial.year : 1900,
                  ),
                  lastDate: DateTime(
                    initial.year > 2100 ? initial.year : 2100,
                    12,
                    31,
                  ),
                );
                if (selected != null && field.mounted) select(selected);
              }
            : null,
        child: InputDecorator(
          isEmpty: date == null,
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            errorText: field.errorText,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            suffixIcon: enabled && canClear && date != null
                ? IconButton(
                    tooltip: 'Clear ${label.toLowerCase()}',
                    icon: const Icon(Icons.clear),
                    onPressed: () => select(null),
                  )
                : null,
          ),
          child: Text(
            date == null
                ? (canClear ? 'Not specified' : 'Select date')
                : MaterialLocalizations.of(context).formatShortDate(date),
          ),
        ),
      );
    },
  );
}
