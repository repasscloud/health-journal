import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/medications/medication_editor.dart';
import '../features/medications/medication_actions.dart';
import '../features/records/record_forms.dart';
import '../features/records/symptom_detail.dart';
import '../data/repositories/journal_repository.dart';
import '../domain/medication.dart';
import '../domain/measurement_units.dart';
import '../domain/records.dart';
import '../domain/regimen.dart';
import '../domain/schedule_occurrences.dart';
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
    this.privacySettings,
    this.reminderSettings,
    this.exportSettings,
    this.backupSettings,
    this.onJournalChanged,
    this.messengerKey,
    this.navigatorKey,
    this.usePhonePreview = false,
  });
  final AppEnvironment environment;
  final Future<bool> Function()? unlockOnStartup;
  final bool usePhonePreview;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;
  final GlobalKey<NavigatorState>? navigatorKey;
  final WidgetBuilder? privacySettings, reminderSettings, exportSettings;
  final VoidCallback? onJournalChanged;
  final WidgetBuilder? backupSettings;
  @override
  State<JournalApp> createState() => _JournalAppState();
}

class _JournalAppState extends State<JournalApp> {
  late final _themeMode = ValueNotifier(
    ThemeMode.values.byName(
      widget.environment.repository?.preferences.appearance.name ?? 'system',
    ),
  );

  late final _lightTheme = journalTheme(Brightness.light);
  late final _darkTheme = journalTheme(Brightness.dark);

  late final router = GoRouter(
    navigatorKey: widget.navigatorKey,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => JournalStartup(
          unlock: widget.environment.isDemo ? null : widget.unlockOnStartup,
          builder: (_) => JournalHome(
            environment: widget.environment,
            themeMode: _themeMode,
            privacySettings: widget.privacySettings,
            reminderSettings: widget.reminderSettings,
            exportSettings: widget.exportSettings,
            backupSettings: widget.backupSettings,
            onJournalChanged: widget.onJournalChanged,
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
        scaffoldMessengerKey: widget.messengerKey,
        builder: (context, child) {
          final journal = BuildNotice(
            review: widget.environment.isReview,
            enabled: widget.environment.isDemo,
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
    this.privacySettings,
    this.reminderSettings,
    this.exportSettings,
    this.backupSettings,
    this.onJournalChanged,
  });
  final AppEnvironment environment;
  final ValueNotifier<ThemeMode> themeMode;
  final WidgetBuilder? privacySettings, reminderSettings, exportSettings;
  final VoidCallback? onJournalChanged;
  final WidgetBuilder? backupSettings;
  @override
  State<JournalHome> createState() => _JournalHomeState();
}

class _JournalHomeState extends State<JournalHome> {
  int selected = 0;
  String search = '';
  String medicationSearch = '';
  String? historyFilter;
  DateTimeRange? historyDates;
  int historyLimit = 20;
  late final _preferences = ValueNotifier(
    widget.environment.repository?.preferences ?? const JournalPreferences(),
  );
  final _savingPreferences = ValueNotifier(false);
  int _settingsRevision = 0;
  MeasurementUnits get units => _preferences.value.units;

  @override
  void dispose() {
    _preferences.dispose();
    _savingPreferences.dispose();
    super.dispose();
  }

  Future<void> _changePreferences(JournalPreferences preferences) async {
    if (_savingPreferences.value) return;
    _savingPreferences.value = true;
    try {
      await widget.environment.repository?.savePreferences(preferences);
      if (!mounted) return;
      _preferences.value = preferences;
      widget.themeMode.value = ThemeMode.values.byName(
        preferences.appearance.name,
      );
      refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save preferences. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        _settingsRevision++;
        _savingPreferences.value = false;
      }
    }
  }

  static const labels = ['Today', 'Medications', 'Symptoms', 'Timeline'];
  static const icons = [
    Icons.today_outlined,
    Icons.medication_outlined,
    Icons.healing_outlined,
    Icons.history,
  ];

  JournalRepository get repository => widget.environment.repository!;

  void refresh() {
    widget.onJournalChanged?.call();
    if (mounted) setState(() {});
  }

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
          remindersAvailable: widget.reminderSettings != null,
        ),
      ),
    );
  }

  void logSymptom() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SymptomForm(
        onSave: (entry) async {
          await repository.addSymptom(entry);
          refresh();
        },
      ),
    ),
  );

  void logMeasurement() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => MeasurementForm(
        units: units,
        onSave: (entry) async {
          await repository.addMeasurement(entry);
          refresh();
        },
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
          final preferences = AnimatedBuilder(
            animation: Listenable.merge([_preferences, _savingPreferences]),
            builder: (context, _) => ListView(
              padding: journalInsets(context, maxWidth: 1016),
              children: settings(),
            ),
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
    if (widget.environment.repository == null) {
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
                      'Personal record entry requires encrypted storage verification for this platform.',
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
                'assets/branding/hj-monogram.png',
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
    final activeMedications = {
      for (final medication in repository.medications)
        if (!medication.archived) medication.id: medication,
    };
    final scheduled = [
      for (final regimen in repository.regimens)
        if (activeMedications[regimen.medicationId] case final medication?)
          for (final occurrence in occurrencesForDate(regimen, now))
            (medication, occurrence),
    ]..sort((a, b) => a.$2.at.compareTo(b.$2.at));
    final linked = {
      for (final event in repository.administrations)
        ?event.occurrenceKey: event.status,
    };
    final activity = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scheduled.isNotEmpty) ...[
          section('Today’s schedule'),
          for (final (medication, occurrence) in scheduled)
            Card(
              child: ListTile(
                title: Text(medication.name),
                subtitle: Text(
                  '${TimeOfDay.fromDateTime(occurrence.at.toLocal()).format(context)} · '
                  '${linked[occurrence.key]?.label ?? (occurrence.at.isBefore(now) ? 'Overdue · Unconfirmed' : 'Scheduled')}',
                ),
                onTap: () => openMedication(medication),
              ),
            ),
        ],
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
              historyDates = null;
              historyLimit = 20;
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
    final range = historyDates;
    final end = range == null
        ? null
        : DateTime(range.end.year, range.end.month, range.end.day + 1);
    final items = repository
        .timeline()
        .where(
          (item) =>
              (matchingIds.contains(item.id) ||
                  matchingReadings.contains(item.id)) &&
              (historyFilter == null || item.type == historyFilter) &&
              (range == null ||
                  (!item.at.isBefore(range.start) && item.at.isBefore(end!))),
        )
        .toList();
    final symptomIds = items
        .where((item) => item.type == 'symptom')
        .map((item) => item.id)
        .toSet();
    final severities = repository.symptoms
        .where((entry) => symptomIds.contains(entry.id))
        .expand(
          (entry) => [?entry.severity, ...entry.pain.map((p) => p.severity)],
        )
        .toList();
    final countsByWeek = <DateTime, int>{};
    for (final item in items.where((item) => item.type == 'symptom')) {
      final day = item.at.toLocal();
      final week = DateTime(day.year, day.month, day.day - (day.weekday - 1));
      countsByWeek.update(week, (count) => count + 1, ifAbsent: () => 1);
    }
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
        onChanged: (value) => setState(() {
          search = value;
          historyLimit = 20;
        }),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in filters.entries)
            ChoiceChip(
              label: Text(filter.value),
              selected: historyFilter == filter.key,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    historyFilter = filter.key;
                    historyLimit = 20;
                  });
                }
              },
            ),
        ],
      ),
      Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(
              range == null
                  ? 'Filter by date'
                  : '${MaterialLocalizations.of(context).formatShortDate(range.start)} – ${MaterialLocalizations.of(context).formatShortDate(range.end)}',
            ),
            onPressed: () async {
              final selected = await showDateRangePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100, 12, 31),
                initialDateRange: range,
              );
              if (selected != null && mounted) {
                setState(() {
                  historyDates = selected;
                  historyLimit = 20;
                });
              }
            },
          ),
          if (range != null)
            TextButton(
              onPressed: () => setState(() {
                historyDates = null;
                historyLimit = 20;
              }),
              child: const Text('Clear dates'),
            ),
        ],
      ),
      if (historyFilter == 'symptom' && symptomIds.isNotEmpty)
        Text(
          '${symptomIds.length} symptom entries'
          '${severities.isEmpty ? '' : ' · Recorded severity ${severities.reduce((a, b) => a < b ? a : b)}–${severities.reduce((a, b) => a > b ? a : b)}/10'}',
        ),
      if (historyFilter == 'symptom' && countsByWeek.isNotEmpty)
        ExpansionTile(
          title: const Text('Weekly symptom entries'),
          children: [
            for (final week in countsByWeek.entries.take(8))
              ListTile(
                title: Text(
                  'Week of ${MaterialLocalizations.of(context).formatShortDate(week.key)}',
                ),
                trailing: Text('${week.value}'),
              ),
          ],
        ),
      if (items.isEmpty) section('No matching events.'),
      ...eventCards(items.take(historyLimit)),
      if (items.length > historyLimit)
        OutlinedButton(
          onPressed: () => setState(() => historyLimit += 20),
          child: const Text('Show more events'),
        ),
    ];
  }

  List<Widget> settings() => [
    section('Units'),
    unitControl(
      kind: MeasurementKind.weight,
      choices: const [DisplayUnit.kilograms, DisplayUnit.pounds],
    ),
    const SizedBox(height: 12),
    unitControl(
      kind: MeasurementKind.temperature,
      choices: const [DisplayUnit.celsius, DisplayUnit.fahrenheit],
    ),
    const SizedBox(height: 12),
    unitControl(
      kind: MeasurementKind.glucose,
      choices: const [DisplayUnit.mmolPerLiter, DisplayUnit.mgPerDeciliter],
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
                  : widget.environment.repository == null
                  ? 'Personal record entry is currently unavailable.'
                  : 'Entries are stored in the encrypted journal on this device.',
            ),
          ),
          ListTile(
            leading: const JournalIcon(Icons.lock_outline),
            title: const Text('Privacy & security'),
            subtitle: Text(
              widget.privacySettings == null
                  ? 'PIN and biometrics are unavailable in this build.'
                  : 'Manage the journal PIN',
            ),
            onTap: widget.privacySettings == null
                ? null
                : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: widget.privacySettings!),
                  ),
          ),
          ListTile(
            leading: const JournalIcon(Icons.backup_outlined),
            title: const Text('Backup and restore'),
            subtitle: Text(
              widget.backupSettings == null
                  ? 'Encrypted backups and restore are unavailable.'
                  : 'Manage password-encrypted backups',
            ),
            onTap: widget.backupSettings == null
                ? null
                : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: widget.backupSettings!),
                  ),
          ),
          ListTile(
            leading: const JournalIcon(Icons.description_outlined),
            title: const Text('Reports and exports'),
            subtitle: Text(
              widget.exportSettings == null
                  ? 'Report generation and health imports are unavailable.'
                  : 'Save a CSV file',
            ),
            onTap: widget.exportSettings == null
                ? null
                : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: widget.exportSettings!),
                  ),
          ),
          ListTile(
            leading: const JournalIcon(Icons.notifications_none),
            title: const Text('Reminders'),
            subtitle: Text(
              widget.reminderSettings == null
                  ? 'This build does not send notifications.'
                  : 'Permissions and test notification',
            ),
            onTap: widget.reminderSettings == null
                ? null
                : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: widget.reminderSettings!),
                  ),
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
  }) => DropdownButtonFormField<DisplayUnit>(
    key: ValueKey((units.preference(kind), _settingsRevision)),
    isExpanded: true,
    initialValue: units.preference(kind),
    decoration: InputDecoration(labelText: kind.label),
    items: [
      for (final choice in choices)
        DropdownMenuItem(value: choice, child: Text(choice.symbol)),
    ],
    onChanged: _savingPreferences.value
        ? null
        : (value) {
            if (value != null) {
              _changePreferences(_preferences.value.withUnit(value));
            }
          },
  );

  Widget appearanceControl() => ValueListenableBuilder<ThemeMode>(
    valueListenable: widget.themeMode,
    builder: (context, mode, _) => DropdownButtonFormField<ThemeMode>(
      key: ValueKey((mode, _settingsRevision)),
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
      onChanged: _savingPreferences.value
          ? null
          : (value) {
              if (value != null) {
                _changePreferences(
                  _preferences.value.withAppearance(
                    JournalAppearance.values.byName(value.name),
                  ),
                );
              }
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
                  if (symptom != null)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SymptomDetail(
                            entry: symptom,
                            onRevise: (updated) async {
                              await repository.reviseSymptom(updated);
                              refresh();
                            },
                            history: () =>
                                repository.symptomHistory(symptom.id),
                          ),
                        ),
                      ),
                      child: const Text('View symptom details'),
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
    required this.remindersAvailable,
  });
  final JournalRepository repository;
  final String id;
  final VoidCallback onChanged;
  final bool recordFirst, remindersAvailable;

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
                remindersAvailable: widget.remindersAvailable,
                onChanged: () {
                  if (mounted) setState(() {});
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
