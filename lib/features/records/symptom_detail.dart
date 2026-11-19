import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/demo_notice.dart';
import '../../app/journal_labels.dart';
import '../../app/journal_theme.dart';
import '../../domain/records.dart';
import 'record_forms.dart';

class SymptomDetail extends StatefulWidget {
  const SymptomDetail({
    super.key,
    required this.entry,
    this.onRevise,
    this.history,
  });
  final FutureOr<void> Function(SymptomEntry)? onRevise;
  final List<SymptomEntry> Function()? history;

  final SymptomEntry entry;

  @override
  State<SymptomDetail> createState() => _SymptomDetailState();
}

class _SymptomDetailState extends State<SymptomDetail> {
  late SymptomEntry entry = widget.entry;

  @override
  Widget build(BuildContext context) {
    final groups = <(String, String), List<(int, PainObservation)>>{};
    for (final (index, point) in entry.pain.indexed) {
      groups.putIfAbsent((point.assetVersion, point.view), () => []).add((
        index + 1,
        point,
      ));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom details')),
      body: JournalBody(
        child: ListView(
          padding: journalInsets(context),
          children: [
            JournalHeading(entry.title),
            const SizedBox(height: 12),
            Text('Onset · ${journalDateTime(context, entry.onsetAt)}'),
            if (entry.endAt case final end?)
              Text('End · ${journalDateTime(context, end)}'),
            Text('Recorded · ${journalDateTime(context, entry.recordedAt)}'),
            if (entry.severity case final severity?)
              Text('Severity · $severity/10'),
            if (entry.notes.isNotEmpty) Text(entry.notes),
            if (entry.category.isNotEmpty) Text('Category · ${entry.category}'),
            if (entry.pattern case final pattern?) Text(journalLabel(pattern)),
            if (entry.triggers.isNotEmpty) Text('Triggers · ${entry.triggers}'),
            if (entry.relief.isNotEmpty)
              Text('Relief measures · ${entry.relief}'),
            if (entry.effect.isNotEmpty)
              Text('Perceived effect · ${entry.effect}'),
            if (widget.onRevise case final revise?)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SymptomForm(
                        previous: entry,
                        onSave: (updated) async {
                          await revise(updated);
                          if (mounted) setState(() => entry = updated);
                        },
                      ),
                    ),
                  ),
                  child: const Text('Edit symptom'),
                ),
              ),
            if (widget.history?.call() case final versions?
                when versions.isNotEmpty)
              ExpansionTile(
                title: const Text('Edit history'),
                children: [
                  for (final version in versions.reversed)
                    ListTile(
                      title: Text(version.title),
                      subtitle: Text(
                        'Saved ${journalDateTime(context, version.updatedAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SymptomDetail(entry: version),
                        ),
                      ),
                    ),
                ],
              ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Pain locations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
            for (final group in groups.entries) ...[
              const SizedBox(height: 16),
              _SavedPainMap(
                version: group.key.$1,
                view: group.key.$2,
                points: group.value,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedPainMap extends StatelessWidget {
  const _SavedPainMap({
    required this.version,
    required this.view,
    required this.points,
  });

  final String version, view;
  final List<(int, PainObservation)> points;

  @override
  Widget build(BuildContext context) {
    final heading = '${journalLabel(view)} · Body map $version';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              heading,
              style: Theme.of(context).textTheme.titleMedium,
              semanticsLabel: '${journalLabel(view)} view, body map $version',
            ),
            Center(
              child: ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: AspectRatio(
                    aspectRatio: 100 / 200,
                    child: LayoutBuilder(
                      builder: (context, bounds) => Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          SvgPicture.asset(
                            'assets/bodymaps/$version/$view.svg',
                            key: ValueKey('saved-map-$version-$view'),
                          ),
                          for (final (_, point) in points)
                            if (point.radius case final radius?)
                              Positioned(
                                left: (point.x - radius) * bounds.maxWidth,
                                top:
                                    point.y * bounds.maxHeight -
                                    radius * bounds.maxWidth,
                                child: Container(
                                  width: 2 * radius * bounds.maxWidth,
                                  height: 2 * radius * bounds.maxWidth,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: journalSeverityColor(
                                      point.severity,
                                      Theme.of(context).brightness,
                                    ).withValues(alpha: .3),
                                  ),
                                ),
                              ),
                          for (final (number, point) in points)
                            Positioned(
                              left: point.x * bounds.maxWidth - 12,
                              top: point.y * bounds.maxHeight - 12,
                              child: Container(
                                key: ValueKey('saved-marker-${point.id}'),
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: journalSeverityColor(
                                    point.severity,
                                    Theme.of(context).brightness,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$number',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
            for (final (number, point) in points)
              Semantics(
                container: true,
                excludeSemantics: true,
                label:
                    'Marker $number, ${journalLabel(view)} view, '
                    '${journalLabel(point.region)}, ${journalLabel(point.painType)}, '
                    'severity ${point.severity} out of 10'
                    '${point.radius == null ? '' : ', area radius ${(point.radius! * 100).round()} percent of map width'}',
                child: Text(
                  '$number. ${journalLabel(point.region)} · '
                  '${journalLabel(point.painType)} · ${point.severity}/10',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
