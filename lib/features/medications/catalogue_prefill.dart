import '../../data/catalogue/catalogue.dart';

const _forms = {
  'oral tablet': 'Tablet',
  'oral capsule': 'Capsule',
  'chewable tablet': 'Chewable tablet',
  'dispersible tablet': 'Dispersible tablet',
  'extended release oral tablet': 'Modified-release tablet',
  'delayed release oral tablet': 'Modified-release tablet',
  'oral solution': 'Liquid solution',
  'oral suspension': 'Oral suspension',
  'oral syrup': 'Syrup',
  'topical cream': 'Cream',
  'topical ointment': 'Ointment',
  'topical gel': 'Gel',
  'topical lotion': 'Lotion',
  'injection': 'Injection',
  'injectable solution': 'Injection',
  'injectable suspension': 'Injection',
  'prefilled syringe': 'Prefilled syringe',
  'metered dose inhaler': 'Inhaler',
  'dry powder inhaler': 'Inhaler',
  'inhalation solution': 'Nebuliser solution',
  'transdermal patch': 'Patch',
  'transdermal system': 'Patch',
  'rectal suppository': 'Suppository',
  'nasal spray': 'Spray',
  'oral powder': 'Powder',
  'oral granules': 'Granules',
};

final _scalar = RegExp(r'^([0-9]+(?:\.[0-9]+)?|\.[0-9]+)\s*(.+)$');
const _units = {
  'ng': 'ng',
  'mcg': 'µg',
  'μg': 'µg',
  'µg': 'µg',
  'mg': 'mg',
  'g': 'g',
  'ml': 'mL',
  'l': 'L',
  'iu': 'IU',
  'unit': 'U',
  'units': 'U',
  'u': 'U',
  'meq': 'mEq',
  'mmol': 'mmol',
  '%': '%',
  'mg/ml': 'mg/mL',
  'mg/5ml': 'mg/5 mL',
  'mg/g': 'mg/g',
  'unit/ml': 'U/mL',
  'units/ml': 'U/mL',
  'unt/ml': 'U/mL',
  'unt': 'U',
  'mcg/dose': 'µg/dose',
};

({String amount, String unit, String form}) cataloguePrefill(
  CatalogueProduct product,
) {
  final form = _forms[product.form.toLowerCase()] ?? '';
  final match = _scalar.firstMatch(
    product.strength.replaceAllMapped(
      RegExp(r'^(\d{1,3}(?:,\d{3})+)(?=[.\s]|$)'),
      (match) => match[0]!.replaceAll(',', ''),
    ),
  );
  if (product.ingredientCount == 1 && match != null) {
    final unit = _units[match[2]!.toLowerCase().replaceAll(RegExp(r'\s+'), '')];
    final amount = match[1]!;
    final number = double.tryParse(amount);
    if (unit != null && number != null && number.isFinite && number > 0) {
      return (amount: amount, unit: unit, form: form);
    }
  }
  return (amount: '', unit: '', form: form);
}
