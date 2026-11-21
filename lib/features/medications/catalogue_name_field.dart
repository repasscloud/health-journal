import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/catalogue/catalogue.dart';

class CatalogueNameField extends StatefulWidget {
  const CatalogueNameField({
    super.key,
    required this.label,
    required this.controller,
    required this.search,
    required this.onSelected,
  });

  final String label;
  final TextEditingController controller;
  final CatalogueSearch? search;
  final ValueChanged<CatalogueProduct>? onSelected;

  @override
  State<CatalogueNameField> createState() => _CatalogueNameFieldState();
}

class _CatalogueNameFieldState extends State<CatalogueNameField> {
  final _focus = FocusNode();
  Timer? _searchTimer;
  int _searchRequest = 0;
  List<CatalogueProduct> _results = const [];
  String? _lookupMessage;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _clearLookup();
    });
  }

  void _clearLookup() {
    _searchTimer?.cancel();
    _searchRequest++;
    setState(() {
      _results = const [];
      _lookupMessage = null;
    });
  }

  void _lookup(String text) {
    final search = widget.search;
    if (search == null) return;
    _clearLookup();
    final query = text.trim();
    if (query.length < 2) return;
    final request = _searchRequest;
    _searchTimer = Timer(const Duration(milliseconds: 180), () async {
      if (!mounted || request != _searchRequest) return;
      setState(() => _lookupMessage = 'Searching catalogue…');
      try {
        final results = await search(query);
        if (!mounted || request != _searchRequest) return;
        setState(() {
          _results = results;
          _lookupMessage = results.isEmpty
              ? 'No catalogue matches. You can enter the details manually.'
              : null;
        });
      } catch (_) {
        if (!mounted || request != _searchRequest) return;
        setState(() {
          _lookupMessage =
              'Catalogue unavailable. You can enter the details manually.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          onChanged: _lookup,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.search == null ? null : 'Search or enter a name',
            suffixIcon: widget.search == null
                ? null
                : IconButton(
                    tooltip: 'About the medication catalogue',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => showAboutDialog(
                      context: context,
                      applicationName: 'Medication catalogue',
                      children: const [
                        Text(
                          'RxTerms is a U.S. catalogue. You can enter any medication manually.',
                        ),
                        SizedBox(height: 12),
                        Text(
                          'This product uses publicly available data from the U.S. National Library '
                          'of Medicine (NLM), National Institutes of Health, Department of Health and '
                          'Human Services; NLM is not responsible for the product and does not '
                          'endorse or recommend this or any other product.',
                        ),
                        SizedBox(height: 12),
                        SelectableText(
                          'Open Database License 1.0\n'
                          'https://opendatacommons.org/licenses/odbl/1-0/\n\n'
                          'https://github.com/repasscloud/health-journal/tree/main/assets/rxterms',
                        ),
                      ],
                    ),
                  ),
          ),
          validator: (text) =>
              text == null || text.trim().isEmpty ? 'Enter a name.' : null,
        ),
        if (_lookupMessage case final message?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(liveRegion: true, child: Text(message)),
          ),
        if (_results.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: ListView.builder(
                primary: false,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final product = _results[index];
                  final details = [
                    if (product.generic != product.name) product.generic,
                    if (product.brand != product.name) product.brand,
                    product.strength,
                    product.form,
                  ].where((detail) => detail.isNotEmpty).join(' · ');
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      [
                        details,
                        product.label,
                      ].where((line) => line.isNotEmpty).join('\n'),
                    ),
                    onTap: widget.onSelected == null
                        ? null
                        : () {
                            _focus.unfocus();
                            _clearLookup();
                            widget.onSelected!(product);
                          },
                  );
                },
              ),
            ),
          ),
      ],
    ),
  );
}
