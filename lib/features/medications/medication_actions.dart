import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/journal_theme.dart';
import '../../app/journal_labels.dart';
import '../../app/calendar_date_field.dart';
import '../../data/repositories/journal_repository.dart';
import '../../domain/medication.dart';
import '../../domain/regimen.dart';
import '../../domain/schedule_occurrences.dart';
import '../../platform/time/device_time_zone.dart';
import 'medication_editor.dart';
import 'medication_forms.dart';
import 'regimen_validation.dart';

class MedicationActions extends StatefulWidget {
  const MedicationActions({
    super.key,
    required this.medication,
    required this.repository,
    required this.onChanged,
    this.recordFirst = false,
  });
  final Medication medication;
  final JournalRepository repository;
  final VoidCallback onChanged;
  final bool recordFirst;
  @override
  State<MedicationActions> createState() => _MedicationActionsState();
}

class _MedicationActionsState extends State<MedicationActions> {
  @override
  void initState() {
    super.initState();
    if (widget.recordFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) record(null);
      });
    }
  }

  Future<void> addRegimen({Regimen? previous}) async {
    final revisionTime = DateTime.now().toUtc();
    final form = GlobalKey<FormState>();
    final amount = TextEditingController(
      text: previous == null ? '' : '${previous.amount}',
    );
    final unit = previous?.unit ?? doseUnitForForm(widget.medication.form);
    final instructions = TextEditingController(
      text: previous?.instructions ?? widget.medication.instructions,
    );
    var end = previous?.effectiveTo?.toLocal();
    var start = DateUtils.dateOnly(revisionTime.toLocal());
    var kind = previous?.kind ?? ScheduleKind.prn;
    final rules = <(TimeOfDay, Set<int>)>[
      if (previous != null && previous.rules.isNotEmpty)
        for (final rule in previous.rules)
          (TimeOfDay(hour: rule.hour, minute: rule.minute), {...rule.weekdays})
      else
        (const TimeOfDay(hour: 8, minute: 0), {1, 2, 3, 4, 5, 6, 7}),
    ];
    String? error;
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(previous == null ? 'Add regimen' : 'Revise regimen'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    CalendarDateField(
                      label: 'Effective start date',
                      value: previous == null ? start : revisionTime,
                      enabled: previous == null,
                      onChanged: (value) {
                        if (value != null) start = value;
                      },
                    ),
                    DropdownButtonFormField<ScheduleKind>(
                      isExpanded: true,
                      initialValue: kind,
                      decoration: const InputDecoration(labelText: 'Schedule'),
                      items: ScheduleKind.values
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text(k.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => update(() => kind = v!),
                    ),
                    TextFormField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Dose amount (not strength)',
                      ),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return n == null || !n.isFinite || n <= 0
                            ? 'Enter a positive amount.'
                            : null;
                      },
                    ),
                    if (unit.isEmpty)
                      const Text(
                        'Choose a specific dosage form in Medication details before adding a regimen.',
                      )
                    else
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: amount,
                        builder: (context, value, _) => InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Dose unit',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          child: Text(
                            doseUnitLabel(unit, double.tryParse(value.text)),
                          ),
                        ),
                      ),
                    TextFormField(
                      controller: instructions,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Directions',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (kind != ScheduleKind.prn) ...[
                      for (final (i, rule) in rules.indexed) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  final chosen = await showTimePicker(
                                    context: context,
                                    initialTime: rule.$1,
                                  );
                                  if (chosen != null && context.mounted) {
                                    update(() => rules[i] = (chosen, rule.$2));
                                  }
                                },
                                child: Text(
                                  'Local time: ${rule.$1.format(context)}',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove time',
                              onPressed: rules.length == 1
                                  ? null
                                  : () => update(() => rules.removeAt(i)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final (index, day) in const [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ].indexed)
                              FilterChip(
                                label: Text(day),
                                selected: rule.$2.contains(index + 1),
                                onSelected: (selected) => update(() {
                                  if (selected) {
                                    rule.$2.add(index + 1);
                                  } else {
                                    rule.$2.remove(index + 1);
                                  }
                                }),
                              ),
                          ],
                        ),
                      ],
                      TextButton(
                        onPressed: () => update(
                          () => rules.add((
                            const TimeOfDay(hour: 18, minute: 0),
                            {1, 2, 3, 4, 5, 6, 7},
                          )),
                        ),
                        child: const Text('Add time'),
                      ),
                    ],
                    if (kind == ScheduleKind.course)
                      CalendarDateField(
                        label: 'Exclusive end date',
                        value: end,
                        onChanged: (value) => end = value,
                        validator: (value) => validateCourseEnd(
                          value,
                          previous == null ? start : revisionTime,
                        ),
                      ),
                    const Text(
                      'New regimens use the start date at local midnight. Revisions take effect now. Reminders are unavailable in this build.',
                    ),
                    if (error != null) Text(error!),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: unit.isEmpty || saving
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      update(() => saving = true);
                      try {
                        final revision = Regimen(
                          id: const Uuid().v4(),
                          medicationId: widget.medication.id,
                          amount: double.parse(amount.text),
                          unit: unit,
                          kind: kind,
                          effectiveFrom: previous == null
                              ? start.toUtc()
                              : revisionTime,
                          effectiveTo: kind == ScheduleKind.course
                              ? end!.toUtc()
                              : null,
                          instructions: instructions.text,
                          rules: kind == ScheduleKind.prn
                              ? []
                              : [
                                  for (final (time, weekdays) in rules)
                                    ScheduleRule(
                                      hour: time.hour,
                                      minute: time.minute,
                                      weekdays: weekdays,
                                    ),
                                ],
                        );
                        if (previous == null) {
                          await widget.repository.addRegimen(revision);
                        } else {
                          await widget.repository.reviseRegimen(
                            previous.id,
                            revision,
                          );
                        }
                        if (mounted) widget.onChanged();
                        if (context.mounted &&
                            ModalRoute.of(context)?.isCurrent == true) {
                          Navigator.pop(context);
                        }
                      } on ArgumentError {
                        if (!context.mounted) return;
                        update(() => saving = false);
                        update(
                          () => error = 'Choose weekdays, distinct times, a valid dose and dates.',
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        update(() => saving = false);
                        update(
                          () => error = 'An effective regimen already exists. Overlapping revisions are not allowed.',
                        );
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final c in [amount, instructions]) {
      c.dispose();
    }
  }

  Future<void> record(Regimen? regimen, {Administration? original}) async {
    final adHoc = regimen == null && original == null;
    var occurred = (original?.occurredAt ?? DateTime.now()).toLocal();
    ScheduleOccurrence? occurrence;
    bool unavailableLocalTime = false;
    void selectLocalTime(DateTime day, int hour, int minute) {
      occurred = DateTime(day.year, day.month, day.day, hour, minute);
      unavailableLocalTime =
          occurred.day != day.day ||
          occurred.hour != hour ||
          occurred.minute != minute;
      occurrence = null;
    }

    final status = adHoc
        ? AdministrationStatus.taken
        : await showDialog<AdministrationStatus>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Choose a dose status'),
              children: [
                for (final s in AdministrationStatus.values)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, s),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          s.label,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: const SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Cancel'),
                    ),
                  ),
                ),
              ],
            ),
          );
    if (status == null || !mounted) return;
    final currentRegimen = adHoc
        ? widget.repository.regimens
              .where(
                (item) =>
                    item.medicationId == widget.medication.id &&
                    item.contains(occurred.toUtc()),
              )
              .firstOrNull
        : regimen;
    final defaultAmount = original?.amount ?? currentRegimen?.amount;
    final formUnit = doseUnitForForm(widget.medication.form);
    final defaultUnit =
        original?.unit ??
        currentRegimen?.unit ??
        (formUnit == 'mL' || formUnit == 'g' ? '' : formUnit);
    var showUnitField = defaultUnit.isEmpty;
    bool validTime() =>
        !unavailableLocalTime &&
        !occurred.isAfter(DateTime.now()) &&
        (regimen == null || regimen.contains(occurred.toUtc()));
    final form = GlobalKey<FormState>();
    final reason = TextEditingController();
    final actualAmount = TextEditingController(
      text: defaultAmount == null ? '' : journalQuantity(defaultAmount),
    );
    final actualUnit = TextEditingController(text: defaultUnit);
    final notes = TextEditingController(text: original?.notes ?? '');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final local = MaterialLocalizations.of(context);
          return AlertDialog(
            title: Text(
              adHoc
                  ? 'Log medication taken'
                  : original == null
                  ? 'Review dose'
                  : 'Review correction',
            ),
            content: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${original?.medicationNameSnapshot ?? widget.medication.name} · ${status.label}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status == AdministrationStatus.taken
                          ? 'When taken'
                          : 'Event date and time',
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(local.formatShortDate(occurred)),
                          onPressed: () async {
                            final day = await showDatePicker(
                              context: context,
                              initialEntryMode:
                                  DatePickerEntryMode.calendarOnly,
                              initialDate: occurred,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (day == null || !context.mounted) return;
                            update(
                              () => selectLocalTime(
                                day,
                                occurred.hour,
                                occurred.minute,
                              ),
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.schedule),
                          label: Text(
                            TimeOfDay.fromDateTime(occurred).format(context),
                          ),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(occurred),
                            );
                            if (time == null || !context.mounted) return;
                            update(
                              () => selectLocalTime(
                                occurred,
                                time.hour,
                                time.minute,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: actualAmount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Recorded dose amount',
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        return amount == null || !amount.isFinite || amount <= 0
                            ? 'Enter a positive amount.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (showUnitField)
                      TextFormField(
                        controller: actualUnit,
                        decoration: const InputDecoration(
                          labelText: 'Recorded dose unit',
                          hintText: 'For example, tablet or mL',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a unit.'
                            : null,
                      )
                    else
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text('Dose unit: ${actualUnit.text}'),
                          TextButton(
                            onPressed: () => update(() => showUnitField = true),
                            child: const Text('Change unit'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notes,
                      decoration: const InputDecoration(
                        labelText: 'Entry notes',
                      ),
                    ),
                    if (original != null) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reason,
                        decoration: const InputDecoration(
                          labelText: 'Correction reason (required)',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a correction reason.'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (regimen != null &&
                        original == null &&
                        regimen.kind != ScheduleKind.prn)
                      DropdownButton<ScheduleOccurrence>(
                        isExpanded: true,
                        value: occurrence,
                        hint: const Text(
                          'Link a scheduled occurrence (optional)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            child: Text('No scheduled occurrence'),
                          ),
                          for (final slot in occurrencesForDate(
                            regimen,
                            occurred,
                          ))
                            if (!widget.repository.administrations.any(
                              (entry) => entry.occurrenceKey == slot.key,
                            ))
                              DropdownMenuItem(
                                value: occurrence?.key == slot.key
                                    ? occurrence
                                    : slot,
                                child: Text(
                                  'Scheduled ${TimeOfDay.fromDateTime(slot.at.toLocal()).format(context)}',
                                ),
                              ),
                        ],
                        onChanged: (selected) =>
                            update(() => occurrence = selected),
                      ),
                    if (unavailableLocalTime)
                      const Text(
                        'That local time does not exist. Choose another time.',
                      ),
                    const Text('Check for duplicates before confirming.'),
                    if (!validTime())
                      Text(
                        regimen == null ? 'Choose a time at or before now.' : 'Choose a time within the regimen dates and at or before now.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: !validTime()
                    ? null
                    : () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                child: Text(adHoc ? 'Save dose' : 'Confirm entry'),
              ),
            ],
          );
        },
      ),
    );
    final eventTime = occurred.toUtc();
    final doseAmount = double.tryParse(actualAmount.text);
    final doseUnit = actualUnit.text.trim();
    final noteText = notes.text;
    final reasonText = reason.text;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    actualAmount.dispose();
    actualUnit.dispose();
    reason.dispose();
    notes.dispose();
    if (accepted != true || !mounted) return;
    final originalZone = await readDeviceTimeZoneId() ?? occurred.timeZoneName;
    if (!mounted) return;
    try {
      if (doseAmount == null) throw ArgumentError('Invalid dose.');
      if (regimen != null && !regimen.contains(eventTime)) {
        throw ArgumentError('Outside regimen.');
      }
      final now = DateTime.now().toUtc();
      await widget.repository.recordAdministration(
        original != null || regimen == null
            ? Administration(
                id: const Uuid().v4(),
                medicationId: original?.medicationId ?? widget.medication.id,
                medicationNameSnapshot:
                    original?.medicationNameSnapshot ?? widget.medication.name,
                medicationSnapshot: original == null
                    ? widget.medication
                    : original.medicationSnapshot,
                regimenId: original?.regimenId,
                regimenSnapshot: original?.regimenSnapshot,
                status: status,
                recordedAt: now,
                occurredAt: eventTime,
                takenAt: status == AdministrationStatus.taken
                    ? eventTime
                    : null,
                amount: doseAmount,
                unit: doseUnit,
                notes: noteText,
                correctsId: original?.id,
                correctionReason: reasonText,
                occurrenceKey: original?.occurrenceKey,
                intendedAt: original?.intendedAt,
                originalZoneLabel: original?.occurredAt == eventTime
                    ? original?.originalZoneLabel
                    : originalZone,
                originalOffsetMinutes: original?.occurredAt == eventTime
                    ? original?.originalOffsetMinutes
                    : occurred.timeZoneOffset.inMinutes,
              )
            : regimen.record(
                eventId: const Uuid().v4(),
                medication: widget.medication,
                status: status,
                recordedAt: now,
                takenAt: status == AdministrationStatus.taken
                    ? eventTime
                    : null,
                occurredAt: eventTime,
                notes: noteText,
                actualAmount: doseAmount,
                actualUnit: doseUnit,
                occurrenceKey: occurrence?.key,
                intendedAt: occurrence?.at,
                originalZoneLabel: originalZone,
                originalOffsetMinutes: occurred.timeZoneOffset.inMinutes,
              ),
      );
      if (mounted) widget.onChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save the dose. Check the amount, unit and date.',
            ),
          ),
        );
      }
    }
  }

  String productDetails(Medication medication) => [
    [
      medication.strength,
      medication.strengthUnit,
    ].where((value) => value.isNotEmpty).join(' '),
    medication.form,
    if (medication.archived) 'Archived',
  ].where((value) => value.isNotEmpty).join(' · ');

  Widget detail(String label, String value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label  ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        TextSpan(text: value),
      ],
    ),
  );

  Widget section(BuildContext context, String label) => Semantics(
    header: true,
    child: Text(label, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget regimenCard(BuildContext context, Regimen regimen) {
    final end = regimen.effectiveTo;
    final canRevise = regimen.contains(DateTime.now().toUtc());
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(regimen.kind.label, style: text.titleMedium),
            Text(
              '${journalQuantity(regimen.amount)} ${doseUnitLabel(regimen.unit, regimen.amount)}',
              style: text.bodyLarge,
            ),
            detail('Starts', journalDateTime(context, regimen.effectiveFrom)),
            if (end != null)
              detail('Ends before', journalDateTime(context, end)),
            for (final rule in regimen.rules)
              detail(
                TimeOfDay(hour: rule.hour, minute: rule.minute).format(context),
                rule.weekdays.length == 7
                    ? 'Every day'
                    : (rule.weekdays.toList()..sort())
                          .map(
                            (day) => const [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][day - 1],
                          )
                          .join(', '),
              ),
            if (regimen.instructions.isNotEmpty &&
                regimen.instructions != widget.medication.instructions)
              detail('Directions', regimen.instructions),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => record(regimen),
                  icon: const Icon(Icons.add),
                  label: const Text('Record dose status'),
                ),
                if (canRevise)
                  TextButton(
                    onPressed: () => addRegimen(previous: regimen),
                    child: const Text('Revise regimen'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget eventCard(
    BuildContext context,
    Administration event,
    Regimen? regimen,
    bool superseded,
  ) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  '${event.status.label} · ${journalQuantity(event.amount)} ${event.unit}',
                  style: text.titleMedium,
                ),
                Text(
                  journalDateTime(context, event.occurredAt),
                  style: text.bodyLarge,
                ),
                if (superseded) const Text('Replaced by a correction'),
                if (event.notes.isNotEmpty) Text(event.notes),
                if (!superseded && (event.regimenId == null || regimen != null))
                  OutlinedButton(
                    onPressed: () => record(regimen, original: event),
                    child: const Text('Correct'),
                  ),
              ],
            ),
          ),
          ExpansionTile(
            title: const Text('Entry details'),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              detail('Medication at the time', event.medicationNameSnapshot),
              detail('Entered', journalDateTime(context, event.recordedAt)),
              if (event.originalOffsetMinutes case final offset?)
                detail(
                  'Original local time',
                  _originalLocalTime(context, event, offset),
                ),
              if (event.intendedAt case final intended?)
                detail('Linked schedule', journalDateTime(context, intended)),
              if (event.correctionReason.isNotEmpty)
                detail('Correction reason', event.correctionReason),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> showCatalogueHistory() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Catalogue history'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              for (final medication in [
                widget.medication,
                ...widget.repository.medicationHistory
                    .where((item) => item.id == widget.medication.id)
                    .toList()
                    .reversed,
              ])
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          medication.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (productDetails(medication).isNotEmpty)
                          Text(productDetails(medication)),
                        detail(
                          'Updated',
                          journalDateTime(context, medication.updatedAt),
                        ),
                        if (medication.instructions.isNotEmpty)
                          detail('Directions', medication.instructions),
                        if (medication.notes.isNotEmpty)
                          detail('Notes', medication.notes),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final medication = widget.medication;
    final regimens = {
      for (final item in widget.repository.regimens)
        if (item.medicationId == medication.id) item.id: item,
    };
    final events =
        widget.repository.administrations
            .where((item) => item.medicationId == medication.id)
            .toList()
          ..sort((a, b) {
            final order = b.occurredAt.compareTo(a.occurredAt);
            return order == 0 ? b.recordedAt.compareTo(a.recordedAt) : order;
          });
    final correctedIds = events.map((event) => event.correctsId).toSet();
    final details = productDetails(medication);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const JournalIcon(Icons.medication_outlined),
            title: Text(
              medication.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: details.isEmpty ? null : Text(details),
            trailing: IconButton(
              tooltip: 'Edit medication',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => editMedication(
                context,
                widget.repository,
                widget.onChanged,
                previous: medication,
              ),
            ),
          ),
          if (medication.instructions.isNotEmpty)
            detail('Directions', medication.instructions),
          if (medication.prescribedBy.isNotEmpty)
            detail('Prescribed by', medication.prescribedBy),
          if (!medication.archived)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => record(null),
                icon: const Icon(Icons.check),
                label: const Text('Log medication taken'),
              ),
            ),
          section(context, 'Regimens'),
          for (final regimen in regimens.values) regimenCard(context, regimen),
          if (regimens.isEmpty)
            Text(
              medication.archived
                  ? 'No regimens were recorded.'
                  : 'No regimens yet. You can still log medication taken.',
            ),
          if (!medication.archived)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: addRegimen,
                icon: const Icon(Icons.add),
                label: const Text('Add regimen'),
              ),
            ),
          const Divider(),
          section(context, 'Dose history'),
          if (events.isEmpty) const Text('No doses recorded.'),
          for (final event in events)
            eventCard(
              context,
              event,
              regimens[event.regimenId],
              correctedIds.contains(event.id),
            ),
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: showCatalogueHistory,
              icon: const Icon(Icons.history),
              label: const Text('Catalogue history'),
            ),
          ),
        ],
      ),
    );
  }
}

String _originalLocalTime(
  BuildContext context,
  Administration event,
  int offset,
) {
  final wall = event.occurredAt.add(Duration(minutes: offset));
  final locale = MaterialLocalizations.of(context);
  final hours = (offset.abs() ~/ 60).toString().padLeft(2, '0');
  final minutes = (offset.abs() % 60).toString().padLeft(2, '0');
  final sign = offset < 0 ? '-' : '+';
  return '${locale.formatShortDate(wall)} at ${TimeOfDay.fromDateTime(wall).format(context)} '
      '${event.originalZoneLabel} (UTC$sign$hours:$minutes)';
}
