final class CatalogueProduct {
  const CatalogueProduct({
    required this.rxcui,
    required this.name,
    required this.generic,
    required this.brand,
    required this.strength,
    required this.form,
    required this.ingredientCount,
    required this.label,
  });

  final String rxcui, name, generic, brand, strength, form, label;
  final int ingredientCount;
}

typedef CatalogueSearch = Future<List<CatalogueProduct>> Function(String query);
