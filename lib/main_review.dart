import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/environment.dart';
import 'app/journal_app.dart';

void main() {
  // The review entry point cannot unlock a production package or production web.
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android ||
      appFlavor != 'review') {
    runApp(
      JournalApp(
        environment: kIsWeb
            ? AppEnvironment.demo()
            : const AppEnvironment.nativePending(),
      ),
    );
    return;
  }
  runApp(JournalApp(environment: AppEnvironment.fictionalReview()));
}
