// Run on a disposable simulator. This target does not open a journal.
import 'package:flutter/material.dart';
import 'package:health_journal/data/catalogue/catalogue.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var result = 'FAIL';
  try {
    final products = await searchBundledCatalogue('Tylenol 500');
    if (products.any((p) => p.rxcui == '209459' && p.strength == '500 mg') &&
        (await searchBundledCatalogue('noRxTermsMatchZxq')).isEmpty) {
      result = 'PASS';
    }
  } catch (error) {
    debugPrint('RxTerms probe error: $error');
  }
  final message = 'HEALTH_JOURNAL_RXTERMS_PROOF:$result';
  debugPrint(message);
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text(message))),
    ),
  );
}
