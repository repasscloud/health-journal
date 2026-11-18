const medicationForms = <String, String>{
  'Tablet': 'tablet',
  'Capsule': 'capsule',
  'Caplet': 'caplet',
  'Chewable tablet': 'tablet',
  'Dispersible tablet': 'tablet',
  'Modified-release tablet': 'tablet',
  'Liquid solution': 'mL',
  'Oral suspension': 'mL',
  'Syrup': 'mL',
  'Drops': 'drop',
  'Cream': 'application',
  'Ointment': 'application',
  'Gel': 'application',
  'Lotion': 'application',
  'Injection': 'mL',
  'Prefilled syringe': 'syringe',
  'Vial': 'vial',
  'Inhaler': 'puff',
  'Nebuliser solution': 'mL',
  'Patch': 'patch',
  'Suppository': 'suppository',
  'Pessary': 'pessary',
  'Spray': 'spray',
  'Powder': 'g',
  'Granules': 'g',
  'Other': '',
};

String doseUnitForForm(String form) {
  final normalized = form.trim().toLowerCase();
  if (normalized == 'sample tablet') return 'tablet';
  for (final entry in medicationForms.entries) {
    if (entry.key.toLowerCase() == normalized) return entry.value;
  }
  return '';
}

String doseUnitLabel(String unit, double? quantity) {
  if (quantity == 1) return unit;
  return switch (unit) {
    'patch' => 'patches',
    'pessary' => 'pessaries',
    'suppository' => 'suppositories',
    'tablet' ||
    'capsule' ||
    'caplet' ||
    'drop' ||
    'application' ||
    'syringe' ||
    'vial' ||
    'puff' ||
    'spray' => '${unit}s',
    _ => unit,
  };
}
