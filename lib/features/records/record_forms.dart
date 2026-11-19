import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

import '../../domain/body_map.dart';
import '../../app/demo_notice.dart';
import '../../app/calendar_date_field.dart';
import '../../app/journal_theme.dart';
import '../../app/journal_labels.dart';
import '../../domain/records.dart';
import '../../domain/measurement_units.dart';

class SymptomForm extends StatefulWidget {
  const SymptomForm({super.key, required this.onSave, this.previous});
  final SymptomEntry? previous;
  final FutureOr<void> Function(SymptomEntry) onSave;
  @override
  State<SymptomForm> createState() => _SymptomFormState();
}

class _SymptomFormState extends State<SymptomForm> {
  final form = GlobalKey<FormState>();
  late final previous = widget.previous;
  late final title = TextEditingController(text: previous?.title);
  late final notes = TextEditingController(text: previous?.notes);
  late final category = TextEditingController(text: previous?.category);
  late final triggers = TextEditingController(text: previous?.triggers);
  late final relief = TextEditingController(text: previous?.relief);
  late final effect = TextEditingController(text: previous?.effect);
  late final pain = [...?previous?.pain];
  late DateTime? onset = previous?.onsetAt;
  late DateTime? end = previous?.endAt;
  late String? pattern = previous?.pattern;
  late int? symptomSeverity = previous?.severity;
  PainObservation? moving;
  final mapKey = GlobalKey();
  double? radius;
  String get assetVersion => moving?.assetVersion ?? currentBodyMapVersion;
  String view = 'front';
  String type = 'aching';
  int severity = 5;
  String? error;
  bool saving = false;
  void add(double x, double y) {
    if (bodyRegionAt(x, y, version: assetVersion, view: view) == null) {
      setState(() => error = 'Choose a point inside the body silhouette.');
      return;
    }
    setState(() {
      error = null;
      final point = PainObservation(
        id: moving?.id ?? const Uuid().v4(),
        view: view,
        x: x,
        y: y,
        severity: moving?.severity ?? severity,
        painType: moving?.painType ?? type,
        radius: radius,
        assetVersion: assetVersion,
      );
      final old = moving;
      if (old == null) {
        pain.add(point);
      } else {
        pain[pain.indexOf(old)] = point;
        moving = point;
      }
    });
  }

  Widget symptomTime(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> change,
  ) {
    final local = value?.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalendarDateField(
          label: '$label date',
          value: value,
          canClear: label == 'End',
          onChanged: (day) => setState(() {
            change(
              day == null
                  ? null
                  : DateTime(
                      day.year,
                      day.month,
                      day.day,
                      local?.hour ?? 0,
                      local?.minute ?? 0,
                    ),
            );
          }),
        ),
        if (local != null)
          TextButton(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(local),
              );
              if (time == null || !mounted) return;
              final chosen = DateTime(
                local.year,
                local.month,
                local.day,
                time.hour,
                time.minute,
              );
              setState(() {
                if (chosen.hour != time.hour || chosen.minute != time.minute) {
                  error =
                      'That local time does not exist. Choose another time.';
                } else {
                  change(chosen);
                  error = null;
                }
              });
            },
            child: Text(
              '$label time · ${TimeOfDay.fromDateTime(local).format(context)}',
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    for (final controller in [
      title,
      notes,
      category,
      triggers,
      relief,
      effect,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(previous == null ? 'Log symptom' : 'Edit symptom'),
    ),
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
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Symptom details'),
              children: [
                symptomTime('Onset', onset, (value) => onset = value),
                const SizedBox(height: 12),
                symptomTime('End', end, (value) => end = value),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: symptomSeverity ?? -1,
                  decoration: const InputDecoration(
                    labelText: 'Overall severity',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: -1,
                      child: Text('Unspecified'),
                    ),
                    for (var value = 0; value <= 10; value++)
                      DropdownMenuItem(value: value, child: Text('$value/10')),
                  ],
                  onChanged: (value) =>
                      symptomSeverity = value == -1 ? null : value,
                ),
                for (final (label, controller) in [
                  ('Category', category),
                  ('Triggers', triggers),
                  ('Relief measures', relief),
                  ('Perceived effect', effect),
                ]) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    decoration: InputDecoration(labelText: label),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: pattern ?? '',
                  decoration: const InputDecoration(labelText: 'Pattern'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Unspecified')),
                    DropdownMenuItem(
                      value: 'continuous',
                      child: Text('Continuous'),
                    ),
                    DropdownMenuItem(
                      value: 'intermittent',
                      child: Text('Intermittent'),
                    ),
                  ],
                  onChanged: (value) => pattern = value == '' ? null : value,
                ),
              ],
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
              onSelectionChanged: (selection) => setState(() {
                moving = null;
                radius = null;
                view = selection.single;
              }),
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
            SwitchListTile(
              title: const Text('Mark an area'),
              value: radius != null,
              onChanged: (value) {
                radius = value ? .05 : null;
                final point = moving;
                if (point == null) {
                  setState(() {});
                } else {
                  add(point.x, point.y);
                }
              },
            ),
            if (radius != null)
              Slider(
                min: .01,
                max: .2,
                divisions: 19,
                value: radius!.clamp(.01, .2),
                label: 'Area radius',
                semanticFormatterCallback: (value) =>
                    'Radius ${(value * 100).round()} percent of map width',
                onChanged: (value) {
                  radius = value;
                  final point = moving;
                  if (point == null) {
                    setState(() {});
                  } else {
                    add(point.x, point.y);
                  }
                },
              ),
            Text(
              view == 'front'
                  ? 'Front: anatomical right is on the viewer’s left.'
                  : 'Back: anatomical left is on the viewer’s left.',
            ),
            Card(
              key: mapKey,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: AspectRatio(
                    aspectRatio: .5,
                    child: LayoutBuilder(
                      builder: (context, bounds) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (tap) => add(
                            tap.localPosition.dx / bounds.maxWidth,
                            tap.localPosition.dy / bounds.maxHeight,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SvgPicture.asset(
                                'assets/bodymaps/$assetVersion/$view.svg',
                                fit: BoxFit.fill,
                                semanticsLabel:
                                    '$view body map. Use the region buttons to select without touch.',
                              ),
                              for (final p in pain.where(
                                (p) =>
                                    p.view == view &&
                                    p.assetVersion == assetVersion,
                              ))
                                if (p.radius case final radius?)
                                  Positioned(
                                    left: (p.x - radius) * bounds.maxWidth,
                                    top:
                                        p.y * bounds.maxHeight -
                                        radius * bounds.maxWidth,
                                    child: Container(
                                      width: 2 * radius * bounds.maxWidth,
                                      height: 2 * radius * bounds.maxWidth,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: journalSeverityColor(
                                          p.severity,
                                          Theme.of(context).brightness,
                                        ).withValues(alpha: .3),
                                      ),
                                    ),
                                  ),
                              for (final p in pain.where(
                                (p) =>
                                    p.view == view &&
                                    p.assetVersion == assetVersion,
                              ))
                                Positioned(
                                  left: p.x * bounds.maxWidth - 12,
                                  top: p.y * bounds.maxHeight - 12,
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
              ),
            ),
            const SizedBox(height: 16),
            Text(
              moving == null
                  ? 'Choose a body region to add a mark'
                  : 'Choose a body region to move the selected mark',
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, bounds) {
                const gap = 12.0;
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final columns = ((bounds.maxWidth + gap) / (110 * scale + gap))
                    .floor()
                    .clamp(1, 3);
                final width = (bounds.maxWidth - (columns - 1) * gap) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final r
                        in assetVersion == 'v1' ? bodyRegionsV1 : bodyRegionsV2)
                      SizedBox(
                        width: width,
                        child: OutlinedButton(
                          onPressed: () => add(r.center.$1, r.center.$2),
                          child: Text(
                            journalLabel(anatomicalRegion(r, view)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (moving != null)
              TextButton(
                onPressed: () => setState(() {
                  moving = null;
                  radius = null;
                }),
                child: const Text('Done editing marker'),
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
                selected: moving == p,
                onTap: () {
                  setState(() {
                    moving = p;
                    view = p.view;
                    radius = p.radius;
                  });
                  final map = mapKey.currentContext;
                  if (map != null) {
                    Scrollable.ensureVisible(
                      map,
                      duration: const Duration(milliseconds: 200),
                    );
                  }
                },
                subtitle: const Text('Select to move or resize'),
                trailing: IconButton(
                  tooltip: 'Delete ${journalLabel(p.region)} observation',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() {
                    pain.remove(p);
                    if (moving == p) {
                      moving = null;
                      radius = null;
                    }
                  }),
                ),
              ),
            const SizedBox(height: 16),
            if (error != null) Semantics(liveRegion: true, child: Text(error!)),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      setState(() => saving = true);
                      try {
                        final now = DateTime.now().toUtc();
                        final starts = onset?.toUtc() ?? now;
                        final ends = end?.toUtc();
                        if (ends != null && ends.isBefore(starts)) {
                          setState(() {
                            saving = false;
                            error = 'Choose an end date and time at or after onset.';
                          });
                          return;
                        }
                        await widget.onSave(
                          SymptomEntry(
                            id: previous?.id ?? const Uuid().v4(),
                            title: title.text,
                            onsetAt: starts,
                            endAt: ends,
                            recordedAt: previous?.recordedAt ?? now,
                            updatedAt: now,
                            severity: symptomSeverity,
                            notes: notes.text,
                            category: category.text,
                            triggers: triggers.text,
                            relief: relief.text,
                            effect: effect.text,
                            pattern: pattern,
                            pain: pain,
                          ),
                        );
                        if (mounted &&
                            ModalRoute.of(this.context)?.isCurrent == true) {
                          Navigator.pop(this.context);
                        }
                      } catch (_) {
                        if (!mounted) return;
                        setState(() => saving = false);
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
  final FutureOr<void> Function(Measurement) onSave;
  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  final form = GlobalKey<FormState>();
  final value = TextEditingController();
  final secondary = TextEditingController();
  var kind = MeasurementKind.weight;
  String? error;
  bool saving = false;
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
              onPressed: saving
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      setState(() => saving = true);
                      try {
                        final now = DateTime.now().toUtc();
                        await widget.onSave(
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
                        if (mounted &&
                            ModalRoute.of(this.context)?.isCurrent == true) {
                          Navigator.pop(this.context);
                        }
                      } catch (_) {
                        if (!mounted) return;
                        setState(() => saving = false);
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
