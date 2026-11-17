import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../domain/medication.dart';
import 'environment.dart';

const demoNotice =
    'DEMO — All records are fictional. Changes reset when you reload. '
    'Do not enter real health information.';

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
  static const labels = [
    'Today',
    'Medications',
    'Symptoms',
    'Timeline',
    'More',
  ];
  Future<void> addMedication() async {
    final controller = TextEditingController();
    final form = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add fictional medication'),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Medication name'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a name.' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    // Dispose after the dialog's exit transition releases its text field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (name == null || !mounted) return;
    setState(
      () => widget.environment.repository!.saveMedication(
        Medication(
          id: const Uuid().v4(),
          name: name,
          strength: '',
          createdAt: DateTime.now().toUtc(),
        ),
      ),
    );
  }

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
                      child: ListTile(
                        title: Text(medication.name),
                        subtitle: const Text('No confirmed administration'),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: addMedication,
                    icon: const Icon(Icons.add),
                    label: const Text('Add fictional medication'),
                  ),
                ],
                if (selected == 2)
                  const Text('Symptom entry is scheduled for milestone 1.'),
                if (selected == 3)
                  const Text(
                    'No administration events recorded in this session.',
                  ),
                if (selected == 4) ...[
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
