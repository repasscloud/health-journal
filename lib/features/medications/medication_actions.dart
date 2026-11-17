import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/journal_repository.dart';
import '../../domain/medication.dart';
import '../../domain/regimen.dart';

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
    final amount = TextEditingController();
    final unit = TextEditingController();
    final instructions = TextEditingController();
    final end = TextEditingController();
    var kind = ScheduleKind.prn;
    var time = const TimeOfDay(hour: 8, minute: 0);
    final weekdays = <int>{1, 2, 3, 4, 5, 6, 7};
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
                    TextButton(
                      onPressed: () async {
                        final chosen = await showTimePicker(
                          context: context,
                          initialTime: time,
                        );
                        if (chosen != null) update(() => time = chosen);
                      },
                      child: Text('Local time: ${time.format(context)}'),
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
                    'Effective now. No reminders are scheduled in demo.',
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
                    effectiveFrom: DateTime.now().toUtc(),
                    effectiveTo: kind == ScheduleKind.course
                        ? DateTime.parse(end.text).toUtc()
                        : null,
                    instructions: instructions.text,
                    rules: kind == ScheduleKind.prn
                        ? []
                        : [
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
                    () => error =
                        'Choose at least one weekday and valid dose and dates.',
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
    for (final c in [amount, unit, instructions, end]) {
      c.dispose();
    }
  }

  Future<void> record(Regimen regimen) async {
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
    try {
      final now = DateTime.now().toUtc();
      widget.repository.recordAdministration(
        regimen.record(
          eventId: const Uuid().v4(),
          medication: widget.medication,
          status: status,
          recordedAt: now,
          takenAt: status == AdministrationStatus.taken ? now : null,
        ),
      );
      widget.onChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not record this status. Check the regimen effective dates.',
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
          subtitle: Text(widget.medication.strength),
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
            title: Text('${e.status.name} • ${e.amount} ${e.unit}'),
            subtitle: Text(
              '${e.medicationNameSnapshot} • ${e.recordedAt.toLocal()}',
            ),
          ),
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No confirmed administration'),
          ),
        Wrap(
          children: [
            TextButton(onPressed: addRegimen, child: const Text('Add regimen')),
            for (final r in regimens.where(
              (r) => r.contains(DateTime.now().toUtc()),
            ))
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
