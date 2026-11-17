import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/medication.dart';
import '../../data/repositories/journal_repository.dart';
import '../../app/demo_notice.dart';

Future<void> editMedication(
  BuildContext context,
  JournalRepository repository,
  VoidCallback onChanged, {
  Medication? previous,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => MedicationEditor(
        repository: repository,
        previous: previous,
        onChanged: onChanged,
      ),
    ),
  );
}

class MedicationEditor extends StatefulWidget {
  const MedicationEditor({
    super.key,
    required this.repository,
    required this.onChanged,
    this.previous,
  });
  final JournalRepository repository;
  final Medication? previous;
  final VoidCallback onChanged;
  @override
  State<MedicationEditor> createState() => _MedicationEditorState();
}

class _MedicationEditorState extends State<MedicationEditor> {
  final formKey = GlobalKey<FormState>();
  late final fields = <String, TextEditingController>{
    for (final entry in <String, String>{
      'Medication name': widget.previous?.name ?? '',
      'Generic name': widget.previous?.genericName ?? '',
      'Brand': widget.previous?.brand ?? '',
      'Form': widget.previous?.form ?? '',
      'Product strength': widget.previous?.strength ?? '',
      'Strength unit': widget.previous?.strengthUnit ?? '',
      'Directions': widget.previous?.instructions ?? '',
      'Reason': widget.previous?.reason ?? '',
      'Prescribed by': widget.previous?.prescribedBy ?? '',
      'Notes': widget.previous?.notes ?? '',
      'Started date': date(widget.previous?.startedAt),
      'Stopped date': date(widget.previous?.stoppedAt),
      'Paused date': date(widget.previous?.pausedAt),
    }.entries)
      entry.key: TextEditingController(text: entry.value),
  };
  late bool archived = widget.previous?.archived ?? false;
  String? error;
  String date(DateTime? d) =>
      d == null ? '' : d.toLocal().toIso8601String().substring(0, 10);
  String value(String key) => fields[key]!.text.trim();
  DateTime? parse(String key) =>
      value(key).isEmpty ? null : DateTime.parse(value(key)).toUtc();
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.previous == null
            ? 'Add fictional medication'
            : 'Edit fictional medication',
      ),
    ),
    body: Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(demoNotice),
            for (final key in fields.keys)
              TextFormField(
                controller: fields[key],
                decoration: InputDecoration(
                  labelText: key,
                  hintText: key.endsWith('date')
                      ? 'YYYY-MM-DD (optional)'
                      : null,
                ),
                validator: (v) {
                  if (key == 'Medication name' &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Enter a name.';
                  }
                  if (key.endsWith('date') && v!.trim().isNotEmpty) {
                    final d = DateTime.tryParse(v.trim());
                    if (d == null ||
                        d.toIso8601String().substring(0, 10) != v.trim()) {
                      return 'Enter a valid YYYY-MM-DD date.';
                    }
                  }
                  return null;
                },
              ),
            SwitchListTile(
              title: const Text('Archived'),
              value: archived,
              onChanged: (v) => setState(() => archived = v),
            ),
            const Text(
              'Archiving retains schedules and history. No reminders run in demo.',
            ),
            if (error != null) Text(error!),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                try {
                  final now = DateTime.now().toUtc();
                  widget.repository.saveMedication(
                    Medication(
                      id: widget.previous?.id ?? const Uuid().v4(),
                      name: value('Medication name'),
                      strength: value('Product strength'),
                      createdAt: widget.previous?.createdAt ?? now,
                      updatedAt: now,
                      genericName: value('Generic name'),
                      brand: value('Brand'),
                      form: value('Form'),
                      strengthUnit: value('Strength unit'),
                      instructions: value('Directions'),
                      reason: value('Reason'),
                      prescribedBy: value('Prescribed by'),
                      notes: value('Notes'),
                      archived: archived,
                      startedAt: parse('Started date'),
                      stoppedAt: parse('Stopped date'),
                      pausedAt: parse('Paused date'),
                    ),
                  );
                  widget.onChanged();
                  Navigator.pop(context);
                } on ArgumentError {
                  setState(
                    () => error =
                        'Check dates: stop and pause must follow start.',
                  );
                } on StateError {
                  setState(() => error = 'Could not save this medication.');
                }
              },
              child: Text(widget.previous == null ? 'Add' : 'Save medication'),
            ),
          ],
        ),
      ),
    ),
  );
}
