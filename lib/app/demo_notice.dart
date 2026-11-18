import 'package:flutter/material.dart';

const demoNotice =
    'DEMO — All records are sample data. Changes reset when you reload. '
    'Do not enter real health information.';

const reviewNotice =
    'Review build — Sample data. Changes reset when the app restarts. Do not enter real health information.';

class BuildNotice extends InheritedWidget {
  const BuildNotice({super.key, required this.review, required super.child});
  final bool review;
  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BuildNotice>()?.review == true
      ? reviewNotice
      : demoNotice;
  @override
  bool updateShouldNotify(BuildNotice oldWidget) => review != oldWidget.review;
}

class BuildBanner extends StatelessWidget {
  const BuildBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1056),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    BuildNotice.of(context),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JournalBody extends StatelessWidget {
  const JournalBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const BuildBanner(),
      Expanded(child: child),
    ],
  );
}
