import 'package:flutter/material.dart';

const demoNotice =
    'DEMO — All records are fictional. Changes reset when you reload. '
    'Do not enter real health information.';

class DemoBody extends StatelessWidget {
  const DemoBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(demoNotice),
        ),
      ),
      Expanded(child: child),
    ],
  );
}
