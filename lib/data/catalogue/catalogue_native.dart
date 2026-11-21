import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

import 'catalogue_product.dart';

const _asset = 'assets/rxterms/catalogue.sqlite';
Future<Database>? _catalogue;
final _word = RegExp(r'[\p{L}\p{N}]+', unicode: true);

Future<Database> _openCatalogue() async {
  final bytes = await rootBundle.load(_asset);
  final temporary = await Directory.systemTemp.createTemp('rxterms-');
  try {
    final file = await File('${temporary.path}/catalogue.sqlite').writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    // Replace this cache file atomically. Each process opens the bundled
    // version, including after an upgrade or downgrade.
    final cached = await file.rename(
      '${Directory.systemTemp.path}/health-journal-rxterms.sqlite',
    );
    return sqlite3.open(cached.path, mode: OpenMode.readOnly);
  } finally {
    await temporary.delete(recursive: true);
  }
}

Future<List<CatalogueProduct>> searchBundledCatalogue(String query) async {
  final tokens = _word.allMatches(query).take(12).map((m) => m[0]!).toList();
  if (tokens.join().length < 2) return const [];
  final opening = _catalogue ??= _openCatalogue();
  final Database db;
  try {
    db = await opening;
  } catch (_) {
    if (identical(opening, _catalogue)) _catalogue = null;
    rethrow;
  }
  return _searchCatalogue(db, tokens);
}

List<CatalogueProduct> _searchCatalogue(Database db, List<String> tokens) {
  // The terms contain only Unicode letters and numbers, so punctuation in the
  // editor cannot become an FTS operator or a SQL wildcard.
  final expression = tokens.map((token) => '"$token"*').join(' ');
  final phrase = tokens.join(' ');
  final rows = db.select(
    '''
    SELECT p.*
    FROM product_search
    JOIN products p ON p.rxcui = product_search.rowid
    WHERE product_search MATCH ?
    ORDER BY CASE
      WHEN p.name = ? COLLATE NOCASE OR p.generic = ? COLLATE NOCASE
        OR p.brand = ? COLLATE NOCASE THEN 0
      WHEN p.name LIKE ? OR p.generic LIKE ? OR p.brand LIKE ? THEN 1
      ELSE 2 END,
      bm25(product_search, 5, 1), p.name COLLATE NOCASE, p.rxcui
    LIMIT 12
    ''',
    [expression, phrase, phrase, phrase, '$phrase%', '$phrase%', '$phrase%'],
  );
  return [
    for (final row in rows)
      CatalogueProduct(
        rxcui: (row['rxcui'] as int).toString(),
        name: row['name'] as String,
        label: row['label'] as String,
        generic: row['generic'] as String,
        brand: row['brand'] as String,
        strength: row['strength'] as String,
        form: row['form'] as String,
        ingredientCount: row['ingredient_count'] as int,
      ),
  ];
}
