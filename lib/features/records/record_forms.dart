import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

import '../../domain/body_map.dart';
import '../../app/demo_notice.dart';
import '../../app/journal_theme.dart';
import '../../app/journal_labels.dart';
import '../../domain/records.dart';
import '../../domain/measurement_units.dart';

class SymptomForm extends StatefulWidget {
  const SymptomForm({super.key, required this.onSave});
  final void Function(SymptomEntry) onSave;
  @override
  State<SymptomForm> createState() => _SymptomFormState();
}

class _SymptomFormState extends State<SymptomForm> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final notes = TextEditingController();
  final pain = <PainObservation>[];
  String view = 'front';
  String type = 'aching';
  int severity = 5;
  String? error;
  void add(double x, double y) {
    if (bodyRegionAt(x, y) == null) {
      setState(() => error = 'Choose a point inside the body silhouette.');
      return;
    }
    setState(() {
      error = null;
      pain.add(
        PainObservation(
          id: const Uuid().v4(),
          view: view,
          x: x,
          y: y,
          severity: severity,
          painType: type,
        ),
      );
    });
  }

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Log symptom')),
    body: JournalBody(
      child: Form(
        key: form,
        child: ListView(
          padding: journalInsets(context, maxWidth: 600),
          children: [
            const JournalHeading(
              'Record a symptom',
              subtitle:
                  'Describe what you felt. Add locations if they’re relevant.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Symptom title'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a symptom title.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              minLines: 2,
              maxLines: 4,
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            Text('Body map', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Tap the silhouette or choose a region below. Each mark has its own severity and type.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'front', label: Text('Front')),
                ButtonSegment(value: 'back', label: Text('Back')),
              ],
              selected: {view},
              onSelectionChanged: (selection) =>
                  setState(() => view = selection.single),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Pain type'),
              items:
                  [
                        'aching',
                        'sharp',
                        'burning',
                        'throbbing',
                        'tingling',
                        'other',
                      ]
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(journalLabel(s)),
                        ),
                      )
                      .toList(),
              onChanged: (s) => setState(() => type = s!),
            ),
            const SizedBox(height: 12),
            Text('Severity for next point: $severity / 10'),
            Slider(
              activeColor: journalSeverityColor(
                severity,
                Theme.of(context).brightness,
              ),
              value: severity.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$severity / 10',
              semanticFormatterCallback: (v) => '${v.round()} out of 10',
              onChanged: (v) => setState(() => severity = v.round()),
            ),
            Text(
              view == 'front'
                  ? 'Front: anatomical right is on the viewer’s left.'
                  : 'Back: anatomical left is on the viewer’s left.',
            ),
            Card(
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 400,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: GestureDetector(
                      onTapUp: (tap) => add(
                        tap.localPosition.dx / 200,
                        tap.localPosition.dy / 400,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SvgPicture.asset(
                            'assets/bodymaps/v1/$view.svg',
                            fit: BoxFit.fill,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).colorScheme.outline,
                              BlendMode.srcIn,
                            ),
                            semanticsLabel:
                                '$view body map, version 1. Use the region buttons to select without touch.',
                          ),
                          for (final p in pain.where((p) => p.view == view))
                            Positioned(
                              left: p.x * 200 - 12,
                              top: p.y * 400 - 12,
                              child: Semantics(
                                label:
                                    '${journalLabel(p.region)}, ${p.severity} out of 10, ${journalLabel(p.painType)}',
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: journalSeverityColor(
                                    p.severity,
                                    Theme.of(context).brightness,
                                  ),
                                  foregroundColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.black
                                      : Colors.white,
                                  child: Text('${p.severity}'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choose a body region to add a mark'),
            Wrap(
              spacing: 8,
              children: [
                for (final r in bodyRegionsV1)
                  OutlinedButton(
                    onPressed: () => add(r.center.$1, r.center.$2),
                    child: Text(journalLabel(anatomicalRegion(r, view))),
                  ),
              ],
            ),
            for (final p in pain)
              ListTile(
                leading: Icon(
                  Icons.circle,
                  size: 14,
                  color: journalSeverityColor(
                    p.severity,
                    Theme.of(context).brightness,
                  ),
                ),
                title: Text(
                  '${journalLabel(p.view)} · ${journalLabel(p.region)} · ${p.severity}/10 · ${journalLabel(p.painType)}',
                ),
                trailing: IconButton(
                  tooltip: 'Delete ${journalLabel(p.region)} observation',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => pain.remove(p)),
                ),
              ),
            const SizedBox(height: 16),
            if (error != null) Semantics(liveRegion: true, child: Text(error!)),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                try {
                  final now = DateTime.now().toUtc();
                  widget.onSave(
                    SymptomEntry(
                      id: const Uuid().v4(),
                      title: title.text,
                      onsetAt: now,
                      recordedAt: now,
                      notes: notes.text,
                      pain: pain,
                    ),
                  );
                  Navigator.pop(context);
                } catch (_) {
                  setState(
                    () => error = 'Could not save the symptom. Check the fields and try again.',
                  );
                }
              },
              child: const Text('Save symptom'),
            ),
          ],
        ),
      ),
    ),
  );
}

class MeasurementForm extends StatefulWidget {
  const MeasurementForm({
    super.key,
    this.units = const MeasurementUnits(),
    required this.onSave,
  });
  final MeasurementUnits units;
  final void Function(Measurement) onSave;
  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final form = GlobalKey<FormState>();
  final value = TextEditingController();
  final secondary = TextEditingController();
  var kind = MeasurementKind.weight;
  String? error;
  String? positive(String? input) {
    final n = double.tryParse(input ?? '');
    return n == null || !n.isFinite || n <= 0
        ? 'Enter a positive number.'
        : null;
  }

  @override
  void dispose() {
    value.dispose();
    secondary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Record measurement')),
    body: JournalBody(
      child: Form(
        key: form,
        child: ListView(
          padding: journalInsets(context, maxWidth: 600),
          children: [
            const JournalHeading(
              'Record a measurement',
              subtitle: 'Enter a reading and its unit.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MeasurementKind>(
              isExpanded: true,
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Measurement type'),
              items: MeasurementKind.values
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                  .toList(),
              onChanged: (k) => setState(() {
                kind = k!;
                value.clear();
                secondary.clear();
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: value,
              validator: (input) {
                final n = double.tryParse(input ?? '');
                if (n == null || !n.isFinite) return 'Enter a number.';
                final canonical = widget.units.toCanonical(kind, n);
                return canonical.isFinite && canonical > 0
                    ? null
                    : 'Enter a valid reading in ${widget.units.symbol(kind)}.';
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText:
                    '${kind == MeasurementKind.bloodPressure ? 'Systolic' : 'Value'} (${widget.units.symbol(kind)})',
              ),
            ),
            if (kind == MeasurementKind.bloodPressure) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: secondary,
                validator: positive,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text('This reading will be recorded at the current time.'),
            const SizedBox(height: 16),
            if (error != null) Semantics(liveRegion: true, child: Text(error!)),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                try {
                  final now = DateTime.now().toUtc();
                  widget.onSave(
                    Measurement(
                      id: const Uuid().v4(),
                      kind: kind,
                      value: widget.units.toCanonical(
                        kind,
                        double.parse(value.text),
                      ),
                      secondary: kind == MeasurementKind.bloodPressure
                          ? double.parse(secondary.text)
                          : null,
                      unit: Measurement.units[kind]!,
                      measuredAt: now,
                      recordedAt: now,
                    ),
                  );
                  Navigator.pop(context);
                } catch (_) {
                  setState(
                    () => error = 'Could not save the measurement. Check the values and try again.',
                  );
                }
              },
              child: const Text('Save measurement'),
            ),
          ],
        ),
      ),
    ),
  );
}
