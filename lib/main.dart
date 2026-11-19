import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/environment.dart';
import 'app/journal_app.dart';
import 'app/production_stub.dart'
    if (dart.library.io) 'app/production_native.dart';

void main() {
  runApp(
    kIsWeb
        ? JournalApp(usePhonePreview: true, environment: AppEnvironment.demo())
        : productionApp(),
  );
}
