import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

import '../../domain/body_map.dart';
import '../../app/demo_notice.dart';
import '../../domain/records.dart';

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
    appBar: AppBar(title: const Text('Log fictional symptom')),
    body: DemoBody(
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Symptom title'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a symptom title.'
                  : null,
            ),
            TextFormField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const Text(
              'Event time: now. Each pain point keeps its own severity and type.',
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: view,
              decoration: const InputDecoration(labelText: 'Body view'),
              items: [
                'front',
                'back',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => setState(() => view = s!),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Pain type'),
              items: [
                'aching',
                'sharp',
                'burning',
                'throbbing',
                'tingling',
                'other',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => setState(() => type = s!),
            ),
            Text('Severity for next point: $severity / 10'),
            Slider(
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
            Center(
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
                          semanticsLabel:
                              '$view body map, version 1. Use the region buttons to select without touch.',
                        ),
                        for (final p in pain.where((p) => p.view == view))
                          Positioned(
                            left: p.x * 200 - 12,
                            top: p.y * 400 - 12,
                            child: Semantics(
                              label:
                                  '${p.region}, ${p.severity} out of 10, ${p.painType}',
                              child: CircleAvatar(
                                radius: 12,
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
            const Text(
              'Accessible region selection: add a point at a region’s centre',
            ),
            Wrap(
              children: [
                for (final r in bodyRegionsV1)
                  TextButton(
                    onPressed: () => add(r.center.$1, r.center.$2),
                    child: Text(anatomicalRegion(r, view)),
                  ),
              ],
            ),
            for (final p in pain)
              ListTile(
                title: Text(
                  '${p.view} ${p.region} • ${p.severity}/10 • ${p.painType}',
                ),
                trailing: IconButton(
                  tooltip: 'Delete ${p.region} observation',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => pain.remove(p)),
                ),
              ),
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
              child: const Text('Save fictional symptom'),
            ),
          ],
        ),
      ),
    ),
  );
}

class MeasurementForm extends StatefulWidget {
  const MeasurementForm({super.key, required this.onSave});
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
    appBar: AppBar(title: const Text('Record fictional measurement')),
    body: DemoBody(
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<MeasurementKind>(
              isExpanded: true,
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Measurement type'),
              items: MeasurementKind.values
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.name)))
                  .toList(),
              onChanged: (k) => setState(() {
                kind = k!;
                value.clear();
                secondary.clear();
              }),
            ),
            TextFormField(
              controller: value,
              validator: positive,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText:
                    '${kind == MeasurementKind.bloodPressure ? 'Systolic' : 'Value'} (${Measurement.units[kind]})',
              ),
            ),
            if (kind == MeasurementKind.bloodPressure)
              TextFormField(
                controller: secondary,
                validator: positive,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                ),
              ),
            const Text(
              'Source: manual • measured now. Values are recorded without clinical interpretation.',
            ),
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
                      value: double.parse(value.text),
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
              child: const Text('Save fictional measurement'),
            ),
          ],
        ),
      ),
    ),
  );
}
