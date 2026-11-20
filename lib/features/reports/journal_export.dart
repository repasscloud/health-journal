import 'package:flutter/material.dart';

class JournalExport extends StatelessWidget {
  const JournalExport({
    super.key,
    required this.onCsv,
    required this.onPdf,
    required this.onShare,
  });

  final VoidCallback onCsv, onPdf, onShare;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reports and exports')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Exported files contain private journal records. Anyone with access to the file can read it. Choose a destination or recipient you trust.',
          ),
          const SizedBox(height: 24),
          Text(
            '30-day PDF report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: onPdf, child: const Text('Save PDF')),
              OutlinedButton(
                onPressed: onShare,
                child: const Text('Share PDF'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Full journal CSV',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Includes journal records and revision history.'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onCsv,
              child: const Text('Choose where to save CSV'),
            ),
          ),
        ],
      ),
    ),
  );
}
