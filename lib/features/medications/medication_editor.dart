import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/catalogue/catalogue.dart';
import '../../domain/medication.dart';
import '../../data/repositories/journal_repository.dart';
import '../../app/demo_notice.dart';
import '../../app/calendar_date_field.dart';
import '../../app/journal_theme.dart';
import 'catalogue_name_field.dart';
import 'catalogue_prefill.dart';
import 'medication_forms.dart';

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
    this.catalogueSearch,
  });
  final JournalRepository repository;
  final Medication? previous;
  final VoidCallback onChanged;
  final CatalogueSearch? catalogueSearch;
  @override
  State<MedicationEditor> createState() => _MedicationEditorState();
}

class _MedicationEditorState extends State<MedicationEditor> {
  static const strengthUnits = {
    'ng': 'Nanogram',
    'µg': 'Microgram',
    'mg': 'Milligram',
    'g': 'Gram',
    'mL': 'Millilitre',
    'L': 'Litre',
    'IU': 'International unit',
    'U': 'Unit',
    'mEq': 'Milliequivalent',
    'mmol': 'Millimole',
    '%': 'Percentage',
    'mg/mL': 'Milligrams per millilitre',
    'mg/5 mL': 'Milligrams per 5 millilitres',
    'mg/g': 'Milligrams per gram',
    'U/mL': 'Units per millilitre',
    'µg/dose': 'Micrograms per dose',
  };
  static final decimalStrength = RegExp(
    r'^(?:[0-9]+(?:[.][0-9]+)?|[.][0-9]+)$',
  );

  static const _nameField = 'Medication name';

  final prescriberFocus = FocusNode();
  int _selectionRevision = 0;

  void _selectProduct(CatalogueProduct product) {
    final mapped = cataloguePrefill(product);
    fields[_nameField]!.text = product.name;
    fields['Generic name']!.text = product.generic;
    fields['Brand']!.text = product.brand;
    fields['Product strength']!.text = mapped.amount;
    setState(() {
      dosageForm = mapped.form;
      strengthUnit = mapped.unit;
      _selectionRevision++;
    });
  }

  late final prescribers = {
    for (final medication in [
      ...widget.repository.medicationHistory,
      ...widget.repository.medications,
    ])
      if (medication.prescribedBy.trim().isNotEmpty)
        medication.prescribedBy.trim().toLowerCase(): medication.prescribedBy
            .trim(),
  }.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  final formKey = GlobalKey<FormState>();
  late final fields = <String, TextEditingController>{
    for (final entry in <String, String>{
      'Medication name': widget.previous?.name ?? '',
      'Generic name': widget.previous?.genericName ?? '',
      'Brand': widget.previous?.brand ?? '',
      'Product strength': widget.previous?.strength ?? '',
      'Directions': widget.previous?.instructions ?? '',
      'Reason': widget.previous?.reason ?? '',
      'Prescribed by': widget.previous?.prescribedBy ?? '',
      'Notes': widget.previous?.notes ?? '',
    }.entries)
      entry.key: TextEditingController(text: entry.value),
  };
  late String dosageForm = widget.previous?.form ?? '';
  late String strengthUnit = widget.previous?.strengthUnit ?? '';
  late bool archived = widget.previous?.archived ?? false;
  String? error;
  bool saving = false;
  late final dates = <String, DateTime?>{
    'Started date': widget.previous?.startedAt,
    'Stopped date': widget.previous?.stoppedAt,
    'Paused date': widget.previous?.pausedAt,
  };
  String value(String key) => fields[key]!.text.trim();

  @override
  void dispose() {
    prescriberFocus.dispose();
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget choiceField(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged, {
    Map<String, String> names = const {},
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      key: ValueKey((label, _selectionRevision)),
      isExpanded: true,
      itemHeight: null,
      initialValue: selected,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Not specified')),
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(
              names.containsKey(option) ? '$option — ${names[option]}' : option,
            ),
          ),
        if (selected.isNotEmpty && !options.contains(selected))
          DropdownMenuItem(
            value: selected,
            child: Text('$selected (existing value)'),
          ),
      ],
      onChanged: (value) => onChanged(value ?? ''),
    ),
  );

  Widget prescriberField() => Autocomplete<String>(
    textEditingController: fields['Prescribed by'],
    focusNode: prescriberFocus,
    optionsViewOpenDirection: OptionsViewOpenDirection.up,
    optionsBuilder: (value) {
      final query = value.text.trim().toLowerCase();
      return prescribers.where((name) => name.toLowerCase().contains(query));
    },
    fieldViewBuilder: (context, controller, focus, submit) => TextFormField(
      controller: controller,
      focusNode: focus,
      textCapitalization: TextCapitalization.words,
      onFieldSubmitted: (_) => submit(),
      decoration: const InputDecoration(
        labelText: 'Prescribed by',
        hintText: 'Find or enter a name',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.previous == null ? 'Add medication' : 'Edit medication',
      ),
    ),
    body: JournalBody(
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: journalInsets(context, maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const JournalHeading(
                'Medication details',
                subtitle: 'Enter the product name and strength as shown on its label.',
              ),
              const SizedBox(height: 16),
              for (final key in fields.keys) ...[
                if (key == 'Product strength')
                  choiceField(
                    'Form',
                    medicationForms.keys.toList(),
                    dosageForm,
                    (value) => dosageForm = value,
                  ),
                if (key == 'Directions')
                  choiceField(
                    'Strength unit',
                    strengthUnits.keys.toList(),
                    strengthUnit,
                    (value) => strengthUnit = value,
                    names: strengthUnits,
                  ),
                if (key == 'Directions')
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Text(
                      'Directions and notes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: switch (key) {
                    _nameField => CatalogueNameField(
                      label: _nameField,
                      controller: fields[_nameField]!,
                      search:
                          widget.catalogueSearch ??
                          (kIsWeb ? null : searchBundledCatalogue),
                      onSelected: saving ? null : _selectProduct,
                    ),
                    'Prescribed by' => prescriberField(),
                    _ => TextFormField(
                      controller: fields[key],
                      minLines: key == 'Directions' ? 3 : 1,
                      maxLines: key == 'Directions' ? 6 : 1,
                      keyboardType: key == 'Product strength'
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(labelText: key),
                      validator: (v) {
                        if (key == 'Product strength') {
                          final strength = v?.trim() ?? '';
                          // Existing records can contain text strengths. Preserve
                          // them unless a new strength is entered.
                          if (strength.isNotEmpty &&
                              strength != widget.previous?.strength) {
                            final number = double.tryParse(strength);
                            if (!decimalStrength.hasMatch(strength) ||
                                number == null ||
                                !number.isFinite ||
                                number <= 0) {
                              return 'Enter a positive number, for example 2.5.';
                            }
                          }
                        }
                        return null;
                      },
                    ),
                  },
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Medication dates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final entry in dates.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CalendarDateField(
                    label: entry.key,
                    value: entry.value,
                    canClear: true,
                    onChanged: (value) => dates[entry.key] = value?.toUtc(),
                  ),
                ),
              SwitchListTile(
                title: const Text('Archived'),
                value: archived,
                onChanged: (v) => setState(() => archived = v),
              ),
              const SizedBox(height: 16),
              if (error != null) Text(error!),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => saving = true);
                        try {
                          final now = DateTime.now().toUtc();
                          await widget.repository.saveMedication(
                            Medication(
                              id: widget.previous?.id ?? const Uuid().v4(),
                              name: value('Medication name'),
                              strength: value('Product strength'),
                              createdAt: widget.previous?.createdAt ?? now,
                              updatedAt: now,
                              genericName: value('Generic name'),
                              brand: value('Brand'),
                              form: dosageForm,
                              strengthUnit: strengthUnit,
                              instructions: value('Directions'),
                              reason: value('Reason'),
                              prescribedBy: value('Prescribed by'),
                              notes: value('Notes'),
                              archived: archived,
                              startedAt: dates['Started date'],
                              stoppedAt: dates['Stopped date'],
                              pausedAt: dates['Paused date'],
                            ),
                          );
                          if (!mounted) return;
                          widget.onChanged();
                          if (ModalRoute.of(this.context)?.isCurrent == true) {
                            Navigator.pop(this.context);
                          }
                        } on ArgumentError {
                          if (!mounted) return;
                          setState(() => saving = false);
                          setState(
                            () => error = 'Check dates: stop and pause must follow start.',
                          );
                        } catch (_) {
                          if (!mounted) return;
                          setState(() => saving = false);
                          setState(
                            () => error = 'Could not save this medication.',
                          );
                        }
                      },
                child: Text(
                  widget.previous == null ? 'Add' : 'Save medication',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
