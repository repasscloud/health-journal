import 'package:flutter/widgets.dart';

import 'environment.dart';
import 'journal_app.dart';

Widget productionApp() =>
    const JournalApp(environment: AppEnvironment.nativePending());
