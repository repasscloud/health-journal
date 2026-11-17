import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/journal_repository.dart';
import '../../domain/medication.dart';
import '../../domain/regimen.dart';
import 'medication_editor.dart';

class MedicationActions extends StatefulWidget {
  const MedicationActions({
    super.key,
    required this.medication,
    required this.repository,
    required this.onChanged,
  });
  final Medication medication;
  final JournalRepository repository;
  final VoidCallback onChanged;
  @override
  State<MedicationActions> createState() => _MedicationActionsState();
}

class _MedicationActionsState extends State<MedicationActions> {
  Future<void> addRegimen({Regimen? previous}) async {
    final form = GlobalKey<FormState>();
    final amount = TextEditingController(
      text: previous == null ? '' : '${previous.amount}',
    );
    final unit = TextEditingController(text: previous?.unit ?? '');
    final instructions = TextEditingController(
      text: previous?.instructions ?? '',
    );
    final end = TextEditingController(
      text:
          previous?.effectiveTo?.toLocal().toIso8601String().substring(0, 10) ??
          '',
    );
    final start = TextEditingController(
      text: DateTime.now().toLocal().toIso8601String().substring(0, 10),
    );
    var kind = previous?.kind ?? ScheduleKind.prn;
    final times = <TimeOfDay>[
      if (previous != null && previous.rules.isNotEmpty)
        for (final rule in previous.rules)
          TimeOfDay(hour: rule.hour, minute: rule.minute)
      else
        const TimeOfDay(hour: 8, minute: 0),
    ];
    final weekdays = <int>{
      if (previous != null && previous.rules.isNotEmpty)
        ...previous.rules.expand((r) => r.weekdays)
      else ...{
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      },
    };
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            previous == null
                ? 'Add fictional regimen'
                : 'Revise fictional regimen',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: start,
                    enabled: previous == null,
                    decoration: const InputDecoration(
                      labelText: 'Effective start date (YYYY-MM-DD)',
                    ),
                    validator: (v) {
                      final d = DateTime.tryParse(v ?? '');
                      return d == null ||
                              d.toIso8601String().substring(0, 10) != v
                          ? 'Enter a valid date.'
                          : null;
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
                            child: Text(
                              k == ScheduleKind.prn
                                  ? 'As needed (no due times)'
                                  : k.name,
                            ),
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
                  TextFormField(
                    controller: unit,
                    decoration: const InputDecoration(labelText: 'Dose unit'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a unit.' : null,
                  ),
                  TextFormField(
                    controller: instructions,
                    decoration: const InputDecoration(labelText: 'Directions'),
                  ),
                  if (kind != ScheduleKind.prn) ...[
                    for (var i = 0; i < times.length; i++)
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final chosen = await showTimePicker(
                                  context: context,
                                  initialTime: times[i],
                                );
                                if (chosen != null) {
                                  update(() => times[i] = chosen);
                                }
                              },
                              child: Text(
                                'Local time: ${times[i].format(context)}',
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove time',
                            onPressed: times.length == 1
                                ? null
                                : () => update(() => times.removeAt(i)),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ],
                      ),
                    TextButton(
                      onPressed: () => update(
                        () => times.add(const TimeOfDay(hour: 18, minute: 0)),
                      ),
                      child: const Text('Add time'),
                    ),
                    const Text('Weekdays (device local time)'),
                    Wrap(
                      children: List.generate(
                        7,
                        (i) => FilterChip(
                          label: Text(
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][i],
                          ),
                          selected: weekdays.contains(i + 1),
                          onSelected: (v) => update(() {
                            v ? weekdays.add(i + 1) : weekdays.remove(i + 1);
                          }),
                        ),
                      ),
                    ),
                  ],
                  if (kind == ScheduleKind.course)
                    TextFormField(
                      controller: end,
                      decoration: const InputDecoration(
                        labelText: 'Exclusive end date (YYYY-MM-DD)',
                      ),
                      validator: (v) {
                        final d = DateTime.tryParse(v ?? '');
                        return d == null ||
                                !d.toUtc().isAfter(DateTime.now().toUtc())
                            ? 'Enter a future end date.'
                            : null;
                      },
                    ),
                  const Text(
                    'New regimens use the start date at local midnight. Revisions take effect now. No demo reminders.',
                  ),
                  if (error != null) Text(error!),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                try {
                  final revision = Regimen(
                    id: const Uuid().v4(),
                    medicationId: widget.medication.id,
                    amount: double.parse(amount.text),
                    unit: unit.text,
                    kind: kind,
                    effectiveFrom: previous == null
                        ? DateTime.parse(start.text).toUtc()
                        : DateTime.now().toUtc(),
                    effectiveTo: kind == ScheduleKind.course
                        ? DateTime.parse(end.text).toUtc()
                        : null,
                    instructions: instructions.text,
                    rules: kind == ScheduleKind.prn
                        ? []
                        : [
                            for (final time in times)
                              ScheduleRule(
                                hour: time.hour,
                                minute: time.minute,
                                weekdays: weekdays,
                              ),
                          ],
                  );
                  if (previous == null) {
                    widget.repository.addRegimen(revision);
                  } else {
                    widget.repository.reviseRegimen(previous.id, revision);
                  }
                  widget.onChanged();
                  Navigator.pop(context);
                } on ArgumentError {
                  update(
                    () => error = 'Choose weekdays, distinct times, a valid dose and dates.',
                  );
                } on StateError {
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
    for (final c in [amount, unit, instructions, end, start]) {
      c.dispose();
    }
  }

  Future<void> record(Regimen regimen, {Administration? original}) async {
    final status = await showDialog<AdministrationStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Record explicit status'),
        children: [
          for (final s in AdministrationStatus.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s),
              child: Text(s.name),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (status == null || !mounted) return;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: (original?.occurredAt ?? DateTime.now()).toLocal(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selectedDate == null || !mounted) return;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        (original?.occurredAt ?? DateTime.now()).toLocal(),
      ),
    );
    if (selectedTime == null || !mounted) return;
    final occurred = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    ).toUtc();
    final reason = TextEditingController();
    final actualAmount = TextEditingController(
      text: '${original?.amount ?? regimen.amount}',
    );
    final actualUnit = TextEditingController(
      text: original?.unit ?? regimen.unit,
    );
    final notes = TextEditingController(text: original?.notes ?? '');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          original == null
              ? 'Confirm fictional entry'
              : 'Correct fictional entry',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Event time: ${occurred.toLocal()} • $status. Existing entries are retained; check for duplicates.',
              ),
              TextField(
                controller: actualAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Recorded dose amount',
                ),
              ),
              TextField(
                controller: actualUnit,
                decoration: const InputDecoration(
                  labelText: 'Recorded dose unit',
                ),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Entry notes'),
              ),
              if (original != null)
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(
                    labelText: 'Correction reason (required)',
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (original == null || reason.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a correction reason.')),
                );
              }
            },
            child: const Text('Confirm entry'),
          ),
        ],
      ),
    );
    final doseAmount = double.tryParse(actualAmount.text);
    final doseUnit = actualUnit.text;
    final noteText = notes.text;
    final reasonText = reason.text;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    actualAmount.dispose();
    actualUnit.dispose();
    reason.dispose();
    notes.dispose();
    if (accepted != true || !mounted) return;
    try {
      if (doseAmount == null) throw ArgumentError('Invalid dose.');
      if (!regimen.contains(occurred)) throw ArgumentError('Outside regimen.');
      final now = DateTime.now().toUtc();
      widget.repository.recordAdministration(
        original != null
            ? Administration(
                id: const Uuid().v4(),
                medicationId: original.medicationId,
                medicationNameSnapshot: original.medicationNameSnapshot,
                medicationSnapshot: original.medicationSnapshot,
                regimenId: original.regimenId,
                regimenSnapshot: original.regimenSnapshot,
                status: status,
                recordedAt: now,
                occurredAt: occurred,
                takenAt: status == AdministrationStatus.taken ? occurred : null,
                amount: doseAmount,
                unit: doseUnit,
                notes: noteText,
                correctsId: original.id,
                correctionReason: reasonText,
              )
            : regimen.record(
                eventId: const Uuid().v4(),
                medication: widget.medication,
                status: status,
                recordedAt: now,
                takenAt: status == AdministrationStatus.taken ? occurred : null,
                occurredAt: occurred,
                notes: noteText,
                actualAmount: doseAmount,
                actualUnit: doseUnit,
              ),
      );
      widget.onChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save: check the dose, unit and event time (within regimen dates and not in the future).',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final regimens = widget.repository.regimens.where(
      (r) => r.medicationId == widget.medication.id,
    );
    final events = widget.repository.administrations.where(
      (e) => e.medicationId == widget.medication.id,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(widget.medication.name),
          subtitle: Text(
            '${widget.medication.strength} ${widget.medication.strengthUnit} • ${widget.medication.form}${widget.medication.archived ? ' • archived' : ''}',
          ),
          trailing: IconButton(
            tooltip: 'Edit medication',
            icon: const Icon(Icons.edit),
            onPressed: () => editMedication(
              context,
              widget.repository,
              widget.onChanged,
              previous: widget.medication,
            ),
          ),
        ),
        for (final r in regimens)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${r.amount} ${r.unit} • ${r.kind.name} • ${r.zonePolicy}\n'
              '${r.rules.map((rule) => rule.localTime).join(', ')} ${r.instructions}',
            ),
          ),
        for (final e in events)
          ListTile(
            trailing: events.any((c) => c.correctsId == e.id)
                ? const Text('Superseded')
                : TextButton(
                    onPressed: () => record(
                      regimens.firstWhere((r) => r.id == e.regimenId),
                      original: e,
                    ),
                    child: const Text('Correct'),
                  ),
            title: Text('${e.status.name} • ${e.amount} ${e.unit}'),
            subtitle: Text(
              '${e.medicationNameSnapshot} • event ${e.occurredAt.toLocal()} • entered ${e.recordedAt.toLocal()}\n${e.notes} ${e.correctionReason}',
            ),
          ),
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No confirmed administration'),
          ),
        Wrap(
          children: [
            if (!widget.medication.archived)
              TextButton(
                onPressed: addRegimen,
                child: const Text('Add regimen'),
              ),
            for (final r in regimens)
              TextButton(
                onPressed: () => record(r),
                child: const Text('Record status'),
              ),
            for (final r in regimens.where(
              (r) => r.contains(DateTime.now().toUtc()),
            ))
              TextButton(
                onPressed: () => addRegimen(previous: r),
                child: const Text('Revise regimen'),
              ),
          ],
        ),
      ],
    );
  }
}
