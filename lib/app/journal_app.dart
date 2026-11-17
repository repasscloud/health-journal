import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/medications/medication_editor.dart';
import '../features/medications/medication_actions.dart';
import '../features/records/record_forms.dart';
import 'environment.dart';
import 'demo_notice.dart';

export 'demo_notice.dart' show demoNotice;

class JournalApp extends StatefulWidget {
  const JournalApp({super.key, required this.environment});
  final AppEnvironment environment;
  @override
  State<JournalApp> createState() => _JournalAppState();
}

class _JournalAppState extends State<JournalApp> {
  late final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => JournalHome(environment: widget.environment),
      ),
    ],
  );
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    child: MaterialApp.router(
      title: 'Health Journal',
      routerConfig: router,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
    ),
  );
}

class JournalHome extends StatefulWidget {
  const JournalHome({super.key, required this.environment});
  final AppEnvironment environment;
  @override
  State<JournalHome> createState() => _JournalHomeState();
}

class _JournalHomeState extends State<JournalHome> {
  int selected = 0;
  String search = '';
  static const labels = [
    'Today',
    'Medications',
    'Symptoms',
    'Timeline',
    'More',
  ];
  Future<void> addMedication() => editMedication(
    context,
    widget.environment.repository!,
    () => setState(() {}),
  );

  @override
  Widget build(BuildContext context) {
    final environment = widget.environment;
    if (!environment.isDemo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health Journal')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Native setup is not available yet. Encrypted storage must '
              'pass iOS and Android security verification before personal records '
              'can be entered. No records have been stored.',
            ),
          ),
        ),
      );
    }
    final repository = environment.repository!;
    return Scaffold(
      appBar: AppBar(title: Text(labels[selected])),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(demoNotice),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (selected == 0) ...[
                  Text(
                    'Your sample day',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text(
                    'No intake is assumed. Record an administration explicitly.',
                  ),
                ],
                if (selected == 0 || selected == 1) ...[
                  for (final medication in repository.medications)
                    Card(
                      child: MedicationActions(
                        medication: medication,
                        repository: repository,
                        onChanged: () => setState(() {}),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: addMedication,
                    icon: const Icon(Icons.add),
                    label: const Text('Add fictional medication'),
                  ),
                ],
                if (selected == 2) ...[
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => SymptomForm(
                          onSave: (s) =>
                              setState(() => repository.addSymptom(s)),
                        ),
                      ),
                    ),
                    child: const Text('Log fictional symptom'),
                  ),
                  for (final s in repository.symptoms)
                    ListTile(
                      title: Text(s.title),
                      subtitle: Text(
                        '${s.notes} • ${s.pain.length} pain observations\n'
                        '${s.pain.map((p) => '${p.view} ${p.region} ${p.severity}/10').join(', ')}',
                      ),
                    ),
                ],
                if (selected == 3) ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search timeline',
                    ),
                    onChanged: (v) => setState(() => search = v),
                  ),
                  if (repository.timeline(search: search).isEmpty)
                    const Text('No matching events.'),
                  for (final item in repository.timeline(search: search))
                    ListTile(
                      title: Text(item.text),
                      subtitle: Text('${item.type} • ${item.at.toLocal()}'),
                    ),
                ],
                if (selected == 4) ...[
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MeasurementForm(
                          onSave: (m) =>
                              setState(() => repository.addMeasurement(m)),
                        ),
                      ),
                    ),
                    child: const Text('Record fictional measurement'),
                  ),
                  for (final m in repository.measurements)
                    ListTile(
                      title: Text(m.display),
                      subtitle: Text('manual • ${m.measuredAt.toLocal()}'),
                    ),

                  const ListTile(
                    title: Text('Backup and restore'),
                    subtitle: Text('Unavailable in demo'),
                  ),
                  const ListTile(
                    title: Text('PIN and biometrics'),
                    subtitle: Text('Unavailable in demo'),
                  ),
                  const ListTile(
                    title: Text('Reminders'),
                    subtitle: Text('Unavailable in demo'),
                  ),
                  const Text(
                    'A private, local-only journal. No accounts, tracking or cloud sync. '
                    'This app records self-reported information and does not provide medical advice.',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (value) => setState(() => selected = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            label: 'Medications',
          ),
          NavigationDestination(
            icon: Icon(Icons.healing_outlined),
            label: 'Symptoms',
          ),
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Timeline'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
