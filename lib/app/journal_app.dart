import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/medications/medication_editor.dart';
import '../features/medications/medication_actions.dart';
import '../features/records/record_forms.dart';
import '../data/repositories/journal_repository.dart';
import '../domain/medication.dart';
import '../domain/measurement_units.dart';
import '../domain/records.dart';
import '../domain/regimen.dart';
import 'environment.dart';
import 'journal_theme.dart';
import 'journal_startup.dart';
import 'journal_labels.dart';
import 'demo_notice.dart';

export 'demo_notice.dart' show demoNotice;

class JournalApp extends StatefulWidget {
  const JournalApp({
    super.key,
    required this.environment,
    this.unlockOnStartup,
    this.usePhonePreview = false,
  });
  final AppEnvironment environment;
  final Future<bool> Function()? unlockOnStartup;
  final bool usePhonePreview;
  @override
  State<JournalApp> createState() => _JournalAppState();
}

class _JournalAppState extends State<JournalApp> {
  final _themeMode = ValueNotifier(ThemeMode.system);

  late final _lightTheme = journalTheme(Brightness.light);
  late final _darkTheme = journalTheme(Brightness.dark);

  late final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => JournalStartup(
          unlock: widget.environment.isDemo ? null : widget.unlockOnStartup,
          builder: (_) => JournalHome(
            environment: widget.environment,
            themeMode: _themeMode,
          ),
        ),
      ),
    ],
  );
  @override
  void dispose() {
    router.dispose();
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    child: ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) => MaterialApp.router(
        title: 'Health Journal',
        builder: (context, child) {
          final journal = BuildNotice(
            review: widget.environment.isReview,
            child: child!,
          );
          if (!widget.usePhonePreview) {
            return journal;
          }
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final media = MediaQuery.of(context);
                    return MediaQuery(
                      data: media.copyWith(
                        size: Size(constraints.maxWidth, media.size.height),
                      ),
                      child: journal,
                    );
                  },
                ),
              ),
            ),
          );
        },
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: _lightTheme,
        darkTheme: _darkTheme,
      ),
    ),
  );
}

class JournalHome extends StatefulWidget {
  const JournalHome({
    super.key,
    required this.environment,
    required this.themeMode,
  });
  final AppEnvironment environment;
  final ValueNotifier<ThemeMode> themeMode;
  @override
  State<JournalHome> createState() => _JournalHomeState();
}

class _JournalHomeState extends State<JournalHome> {
  int selected = 0;
  String search = '';
  String medicationSearch = '';
  String? historyFilter;
  var units = const MeasurementUnits();
  static const labels = ['Today', 'Medications', 'Symptoms', 'Timeline'];
  static const icons = [
    Icons.today_outlined,
    Icons.medication_outlined,
    Icons.healing_outlined,
    Icons.history,
  ];

  JournalRepository get repository => widget.environment.repository!;

  void refresh() => setState(() {});

  Future<void> addMedication() => editMedication(context, repository, refresh);

  void openMedication(Medication medication, {bool recordFirst = false}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _MedicationPage(
          repository: repository,
          id: medication.id,
          onChanged: refresh,
          recordFirst: recordFirst,
        ),
      ),
    );
  }

  void logSymptom() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SymptomForm(
        onSave: (entry) => setState(() => repository.addSymptom(entry)),
      ),
    ),
  );

  void logMeasurement() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => MeasurementForm(
        units: units,
        onSave: (entry) => setState(() => repository.addMeasurement(entry)),
      ),
    ),
  );

  Future<void> chooseMedication() async {
    final medication = await showDialog<Medication>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a medication'),
        children: [
          for (final item in repository.medications)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (mounted && medication != null) {
      openMedication(medication, recordFirst: true);
    }
  }

  FilledButton action(String label, IconData icon, VoidCallback onPressed) =>
      FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );

  Widget settingsButton() => IconButton(
    tooltip: 'Settings',
    icon: const Icon(Icons.settings_outlined),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final preferences = ListView(
            padding: journalInsets(context, maxWidth: 1016),
            children: settings(),
          );
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: SafeArea(
              child: widget.environment.isDemo
                  ? JournalBody(child: preferences)
                  : preferences,
            ),
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.environment.isDemo) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Journal'),
          actions: [settingsButton()],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: journalInsets(context),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const JournalIcon(Icons.lock_outline),
                    const SizedBox(height: 16),
                    const JournalHeading('Setup unavailable'),
                    const SizedBox(height: 12),
                    const Text(
                      'Personal record entry requires encrypted storage verification on iOS and Android. No records have been stored.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final pages = <List<Widget> Function()>[
      today,
      medications,
      symptoms,
      history,
    ];
    return Scaffold(
      appBar: AppBar(
        actions: [settingsButton()],
        titleSpacing: journalInsets(context, maxWidth: 1016).left,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'web/icons/Icon-192.png',
                width: 40,
                height: 40,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Health Journal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: JournalBody(
          child: ListView(
            key: ValueKey(selected),
            padding: journalInsets(context, maxWidth: 1016),
            children: pages[selected](),
          ),
        ),
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (value) =>
                  setState(() => selected = value),
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> today() {
    final local = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final events = repository.timeline().where(
      (item) => item.type != 'schedule',
    );
    final daily = events
        .where((item) => DateUtils.isSameDay(item.at.toLocal(), now))
        .toList();
    // Historical fixtures can have many readings at the same time. Keep the
    // dashboard preview representative and show the full sequence in Timeline.
    final previewCounts = <String, int>{};
    final preview = daily.isNotEmpty
        ? daily
        : events.where((item) {
            final count = previewCounts.update(
              item.type,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
            return count <= 2;
          });
    final activity = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(daily.isEmpty ? 'Recent activity' : 'Today’s activity'),
        if (events.isEmpty)
          const Card(
            child: ListTile(
              leading: JournalIcon(Icons.history),
              title: Text('Your journal is empty'),
              subtitle: Text('Record a dose, symptom or measurement to start.'),
            ),
          )
        else
          ...eventCards(preview.take(6)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() {
              selected = 3;
              search = '';
              historyFilter = null;
            }),
            child: const Text('View full timeline'),
          ),
        ),
      ],
    );
    final quick = Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            section('Record an entry'),
            action(
              'Record medication',
              Icons.medication_outlined,
              chooseMedication,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: logSymptom,
              icon: const Icon(Icons.healing_outlined),
              label: const Text('Log symptom'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: logMeasurement,
              icon: const Icon(Icons.monitor_heart_outlined),
              label: const Text('Record measurement'),
            ),
          ],
        ),
      ),
    );
    return [
      JournalHeading('Today', subtitle: local.formatFullDate(now)),
      if (daily.isNotEmpty) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (type, label, icon) in const [
              ('medication', 'Dose records', Icons.medication_outlined),
              ('symptom', 'Symptoms logged', Icons.healing_outlined),
              ('measurement', 'Measurements', Icons.monitor_heart_outlined),
            ])
              Chip(
                avatar: Icon(icon, size: 16),
                label: Text(
                  '${daily.where((item) => item.type == type).length} $label',
                ),
              ),
          ],
        ),
      ],
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return Column(
              children: [quick, const SizedBox(height: 24), activity],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: activity),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: quick),
            ],
          );
        },
      ),
    ];
  }

  List<Widget> medications() {
    final query = medicationSearch.trim().toLowerCase();
    final matches = repository.medications.where(
      (medication) => [
        medication.name,
        medication.genericName,
        medication.brand,
        medication.strength,
        medication.form,
      ].any((field) => field.toLowerCase().contains(query)),
    );
    return [
      const JournalHeading(
        'Medications',
        subtitle: 'Manage your catalogue, regimens and dose history.',
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: action('Add medication', Icons.add, addMedication),
      ),
      section('Medication catalogue'),
      TextFormField(
        initialValue: medicationSearch,
        decoration: const InputDecoration(
          labelText: 'Search medications',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) => setState(() => medicationSearch = value),
      ),
      const SizedBox(height: 12),
      if (matches.isEmpty)
        const Card(child: ListTile(title: Text('No matching medications'))),
      for (final medication in matches)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Semantics(
              container: true,
              child: ListTile(
                leading: const JournalIcon(Icons.medication_outlined),
                title: Text(medication.name),
                subtitle: Text(
                  [
                    [
                      medication.strength,
                      medication.strengthUnit,
                    ].where((v) => v.isNotEmpty).join(' '),
                    medication.form,
                    if (medication.archived) 'Archived',
                  ].where((v) => v.isNotEmpty).join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openMedication(medication),
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> symptoms() => [
    const JournalHeading(
      'Symptoms',
      subtitle: 'Record what you feel and mark where it hurts.',
    ),
    const SizedBox(height: 16),
    Align(
      alignment: Alignment.centerLeft,
      child: action('Log symptom', Icons.add, logSymptom),
    ),
    section('Symptom journal'),
    if (repository.symptoms.isEmpty)
      const Card(child: ListTile(title: Text('No symptoms recorded'))),
    ...eventCards(
      repository.timeline().where((item) => item.type == 'symptom'),
    ),
  ];

  List<Widget> history() {
    const filters = {
      null: 'All',
      'medication': 'Doses',
      'symptom': 'Symptoms',
      'measurement': 'Measurements',
      'schedule': 'Regimens',
    };
    final query = search.trim().toLowerCase();
    final matchingIds = repository
        .timeline(search: search)
        .map((item) => item.id)
        .toSet();
    final matchingReadings = repository.measurements
        .where(
          (reading) => units.describe(reading).toLowerCase().contains(query),
        )
        .map((reading) => reading.id)
        .toSet();
    final items = repository.timeline().where(
      (item) =>
          (matchingIds.contains(item.id) ||
              matchingReadings.contains(item.id)) &&
          (historyFilter == null || item.type == historyFilter),
    );
    return [
      const JournalHeading(
        'Timeline',
        subtitle: 'Review events in the order they happened.',
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: search,
        decoration: const InputDecoration(
          labelText: 'Search timeline',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) => setState(() => search = value),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        children: [
          for (final filter in filters.entries)
            ChoiceChip(
              label: Text(filter.value),
              selected: historyFilter == filter.key,
              onSelected: (value) =>
                  setState(() => historyFilter = value ? filter.key : null),
            ),
        ],
      ),
      if (items.isEmpty) section('No matching events.'),
      ...eventCards(items),
    ];
  }

  List<Widget> settings() => [
    section('Units'),
    unitControl(
      kind: MeasurementKind.weight,
      choices: const [DisplayUnit.kilograms, DisplayUnit.pounds],
      onChanged: (value) => units = MeasurementUnits(
        weight: value,
        temperature: units.temperature,
        glucose: units.glucose,
      ),
    ),
    const SizedBox(height: 12),
    unitControl(
      kind: MeasurementKind.temperature,
      choices: const [DisplayUnit.celsius, DisplayUnit.fahrenheit],
      onChanged: (value) => units = MeasurementUnits(
        weight: units.weight,
        temperature: value,
        glucose: units.glucose,
      ),
    ),
    const SizedBox(height: 12),
    unitControl(
      kind: MeasurementKind.glucose,
      choices: const [DisplayUnit.mmolPerLiter, DisplayUnit.mgPerDeciliter],
      onChanged: (value) => units = MeasurementUnits(
        weight: units.weight,
        temperature: units.temperature,
        glucose: value,
      ),
    ),
    const SizedBox(height: 16),
    section('Appearance'),
    appearanceControl(),
    const SizedBox(height: 16),
    section('Privacy & device features'),
    Card(
      child: Column(
        children: [
          ListTile(
            leading: const JournalIcon(Icons.storage_outlined),
            title: const Text('Local storage'),
            subtitle: Text(
              widget.environment.isDemo
                  ? 'Entries are held in memory for this session.'
                  : 'Personal record entry is currently unavailable.',
            ),
          ),
          const ListTile(
            leading: JournalIcon(Icons.lock_outline),
            title: Text('Privacy & security'),
            subtitle: Text('PIN and biometrics are unavailable in this build.'),
          ),
          const ListTile(
            leading: JournalIcon(Icons.backup_outlined),
            title: Text('Backup and restore'),
            subtitle: Text('Encrypted backups and restore are unavailable.'),
          ),
          const ListTile(
            leading: JournalIcon(Icons.description_outlined),
            title: Text('Reports and exports'),
            subtitle: Text(
              'Report generation and health imports are unavailable.',
            ),
          ),
          const ListTile(
            leading: JournalIcon(Icons.notifications_none),
            title: Text('Reminders'),
            subtitle: Text('This build does not send notifications.'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    const Text(
      'Health Journal records self-reported information and does not provide medical advice.',
    ),
  ];

  Widget unitControl({
    required MeasurementKind kind,
    required List<DisplayUnit> choices,
    required ValueChanged<DisplayUnit> onChanged,
  }) => DropdownButtonFormField<DisplayUnit>(
    isExpanded: true,
    initialValue: units.preference(kind),
    decoration: InputDecoration(labelText: kind.label),
    items: [
      for (final choice in choices)
        DropdownMenuItem(value: choice, child: Text(choice.symbol)),
    ],
    onChanged: (value) {
      if (value != null) setState(() => onChanged(value));
    },
  );

  Widget appearanceControl() => ValueListenableBuilder<ThemeMode>(
    valueListenable: widget.themeMode,
    builder: (context, mode, _) => DropdownButtonFormField<ThemeMode>(
      initialValue: mode,
      decoration: const InputDecoration(
        labelText: 'Theme',
        prefixIcon: Icon(Icons.contrast),
      ),
      items: const [
        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
      ],
      onChanged: (value) {
        if (value != null) widget.themeMode.value = value;
      },
    ),
  );

  Widget section(String label) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 10),
    child: Semantics(
      header: true,
      child: Text(label, style: Theme.of(context).textTheme.titleLarge),
    ),
  );

  List<Widget> eventCards(Iterable<TimelineItem> items) {
    final local = MaterialLocalizations.of(context);
    DateTime? last;
    final doses = {
      for (final dose in repository.administrations) dose.id: dose,
    };
    final symptoms = {
      for (final symptom in repository.symptoms) symptom.id: symptom,
    };
    final regimens = {
      for (final regimen in repository.regimens) regimen.id: regimen,
    };
    final readings = {
      for (final reading in repository.measurements) reading.id: reading,
    };
    final replaced = doses.values.map((dose) => dose.correctsId).toSet();
    final cards = <Widget>[];
    for (final item in items) {
      final day = item.at.toLocal();
      if (!DateUtils.isSameDay(last, day)) {
        cards.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
            child: Text(
              local.formatFullDate(day),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        );
      }
      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: eventCard(
            item,
            dose: doses[item.id],
            symptom: symptoms[item.id],
            schedule: regimens[item.id],
            reading: readings[item.id],
            doseReplaced: replaced.contains(item.id),
          ),
        ),
      );
      last = day;
    }
    return cards;
  }

  Widget eventCard(
    TimelineItem item, {
    Administration? dose,
    SymptomEntry? symptom,
    Regimen? schedule,
    Measurement? reading,
    required bool doseReplaced,
  }) {
    final (icon, type) = switch (item.type) {
      'medication' => (Icons.medication_outlined, 'Dose record'),
      'symptom' => (Icons.healing_outlined, 'Symptom'),
      'measurement' => (Icons.monitor_heart_outlined, 'Measurement'),
      _ => (Icons.event_note_outlined, 'Regimen'),
    };
    final firstLine = item.text.split(' • ').first;
    final title =
        dose?.medicationNameSnapshot ??
        symptom?.title ??
        (reading == null ? firstLine : units.describe(reading));
    final time = TimeOfDay.fromDateTime(item.at.toLocal()).format(context);
    final text = Theme.of(context).textTheme;
    final notes = dose?.notes ?? symptom?.notes ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JournalIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  Text(title, style: text.titleMedium),
                  Text('$type · $time'),
                  if (dose != null)
                    Text(
                      '${dose.status.label} · ${journalQuantity(dose.amount)} ${dose.unit}',
                    ),
                  if (doseReplaced)
                    const Text('Replaced by a correction')
                  else if (dose?.correctsId != null)
                    const Text('Corrected entry'),
                  if (schedule != null)
                    Text(
                      '${schedule.kind.label} · ${journalQuantity(schedule.amount)} ${schedule.unit}',
                    ),
                  if (schedule != null) const Text('Schedule only'),
                  if (item.type == 'measurement') const Text('Manual entry'),
                  if (notes.isNotEmpty) Text(notes),
                  if (symptom != null)
                    for (final point in symptom.pain)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Icon(
                              Icons.circle,
                              size: 12,
                              color: journalSeverityColor(
                                point.severity,
                                Theme.of(context).brightness,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${journalLabel(point.region)} (${journalLabel(point.view)}) · ${point.severity}/10',
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationPage extends StatefulWidget {
  const _MedicationPage({
    required this.repository,
    required this.id,
    required this.onChanged,
    required this.recordFirst,
  });
  final JournalRepository repository;
  final String id;
  final VoidCallback onChanged;
  final bool recordFirst;

  @override
  State<_MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<_MedicationPage> {
  @override
  Widget build(BuildContext context) {
    final medication = widget.repository.medications.firstWhere(
      (item) => item.id == widget.id,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Medication details')),
      body: JournalBody(
        child: ListView(
          padding: journalInsets(context),
          children: [
            Card(
              child: MedicationActions(
                medication: medication,
                repository: widget.repository,
                recordFirst: widget.recordFirst,
                onChanged: () {
                  setState(() {});
                  widget.onChanged();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
