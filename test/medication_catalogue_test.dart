import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/catalogue/catalogue.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/features/medications/catalogue_prefill.dart';
import 'package:health_journal/features/medications/medication_editor.dart';

const tylenol = CatalogueProduct(
  rxcui: '209459',
  name: 'TYLENOL',
  label: 'acetaminophen 500 MG Oral Tablet [Tylenol]',
  generic: 'acetaminophen',
  brand: 'TYLENOL',
  strength: '500 mg',
  form: 'Oral Tablet',
  ingredientCount: 1,
);

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> enter(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(field(label));
  await tester.enterText(field(label), value);
  await tester.pump();
}

Future<void> save(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled SQLite searches names, combinations, and excludes retired products', () async {
    final brand = await searchBundledCatalogue('tYlEnOl 500');
    expect(brand.map((product) => product.rxcui), contains('209459'));
    final generic = await searchBundledCatalogue('acetaminophen 500');
    expect(generic, isNotEmpty);
    final combo = await searchBundledCatalogue('amoxicillin clavulanate 875');
    expect(combo, isNotEmpty);
    expect(combo.first.generic, contains('clavulanate'));
    expect(cataloguePrefill(combo.first).amount, isEmpty);
    final retired = await searchBundledCatalogue('Advil Liquigel');
    expect(retired.map((product) => product.rxcui), isNot(contains('213325')));
    expect(await searchBundledCatalogue('zyqxnone " OR *'), isEmpty);
  });

  test(
    'maps supported product strengths and leaves uncertain strengths blank',
    () {
      expect(cataloguePrefill(tylenol), (
        amount: '500',
        unit: 'mg',
        form: 'Tablet',
      ));
      CatalogueProduct product(String strength, int ingredients) =>
          CatalogueProduct(
            rxcui: '1',
            name: 'Sample',
            label: '',
            generic: '',
            brand: '',
            strength: strength,
            form: 'Unknown form',
            ingredientCount: ingredients,
          );
      expect(cataloguePrefill(product('1,250 mcg', 1)), (
        amount: '1250',
        unit: 'µg',
        form: '',
      ));
      expect(cataloguePrefill(product('125 mg/5 mL', 1)).unit, 'mg/5 mL');
      expect(cataloguePrefill(product('5-10 mg', 2)).amount, isEmpty);
      expect(cataloguePrefill(product('10 mg', 0)).amount, isEmpty);
      expect(cataloguePrefill(product('10 unsupported', 1)).amount, isEmpty);
    },
  );

  testWidgets(
    'selection prefills editable fields and saves the edited values',
    (tester) async {
      final repository = DemoRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: MedicationEditor(
            repository: repository,
            onChanged: () {},
            catalogueSearch: (_) async => [tylenol],
          ),
        ),
      );
      await enter(tester, 'Medication name', 'tyle');
      await tester.pump(const Duration(milliseconds: 180));
      await tester.tap(find.text('TYLENOL'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(field('Generic name')).controller!.text,
        'acetaminophen',
      );
      expect(
        tester.widget<TextField>(field('Brand')).controller!.text,
        'TYLENOL',
      );
      expect(
        tester.widget<TextField>(field('Product strength')).controller!.text,
        '500',
      );
      await enter(tester, 'Product strength', '325');
      await enter(tester, 'Brand', 'My label');
      await save(tester, 'Add');
      final result = repository.medications.singleWhere(
        (med) => med.name == 'TYLENOL',
      );
      expect(result.brand, 'My label');
      expect(result.strength, '325');
      expect(result.strengthUnit, 'mg');
      expect(result.form, 'Tablet');
    },
  );

  testWidgets(
    'an older response cannot replace a newer query, and errors allow manual edits',
    (tester) async {
      final repository = DemoRepository();
      final original = Medication(
        id: 'existing',
        name: 'Custom original',
        brand: 'Original brand',
        instructions: 'Existing directions',
        strength: '7',
        strengthUnit: 'mg',
        createdAt: DateTime.utc(2025),
      );
      repository.saveMedication(original);
      final slow = Completer<List<CatalogueProduct>>();
      await tester.pumpWidget(
        MaterialApp(
          home: MedicationEditor(
            repository: repository,
            previous: original,
            onChanged: () {},
            catalogueSearch: (query) async => switch (query) {
              'ty' => slow.future,
              'Catalogue error' => throw StateError('missing bundle'),
              _ => [],
            },
          ),
        ),
      );
      await enter(tester, 'Medication name', 'ty');
      await tester.pump(const Duration(milliseconds: 180));
      await enter(tester, 'Medication name', 'Custom offline medicine');
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.textContaining('No catalogue matches'), findsOneWidget);

      slow.complete([tylenol]);
      await tester.pumpAndSettle();
      expect(find.text('TYLENOL'), findsNothing);
      await enter(tester, 'Medication name', 'Catalogue error');
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.textContaining('Catalogue unavailable'), findsOneWidget);
      await save(tester, 'Save medication');
      final saved = repository.medications.singleWhere(
        (med) => med.id == original.id,
      );
      expect(saved.name, 'Catalogue error');
      expect(saved.brand, original.brand);
      expect(saved.instructions, original.instructions);
      expect(saved.strength, original.strength);
    },
  );

  testWidgets(
    'reopening a saved medication after a catalogue refresh preserves its values',
    (tester) async {
      final repository = DemoRepository();
      final saved = Medication(
        id: 'saved-id',
        name: 'TYLENOL',
        brand: 'User-edited label',
        strength: '300',
        strengthUnit: 'mg',
        createdAt: DateTime.utc(2025),
      );
      repository.saveMedication(saved);
      var lookupCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MedicationEditor(
            repository: repository,
            previous: saved,
            onChanged: () {},
            catalogueSearch: (_) async {
              lookupCount++;
              return [tylenol];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(lookupCount, 0);
      expect(
        tester.widget<TextField>(field('Brand')).controller!.text,
        saved.brand,
      );
      expect(
        tester.widget<TextField>(field('Product strength')).controller!.text,
        saved.strength,
      );
      await save(tester, 'Save medication');
      final reopened = repository.medications.singleWhere(
        (med) => med.id == saved.id,
      );
      expect(reopened.brand, saved.brand);
      expect(reopened.strength, saved.strength);
      expect(reopened.createdAt, saved.createdAt);
    },
  );
}
