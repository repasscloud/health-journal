import 'package:flutter/material.dart';

class JournalExport extends StatelessWidget {
  const JournalExport({super.key, required this.onExport});

  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports and exports')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Export the journal as CSV',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'The file contains your journal records and revision history. Anyone with access to the exported file can read it. Choose a destination you trust.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onExport,
              child: const Text('Choose where to save CSV'),
            ),
          ),
        ],
      ),
    ),
  );
}
