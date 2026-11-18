import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/environment.dart';
import 'app/journal_app.dart';

void main() {
  runApp(
    JournalApp(
      usePhonePreview: kIsWeb,
      environment: kIsWeb
          ? AppEnvironment.demo()
          : const AppEnvironment.nativePending(),
    ),
  );
}
