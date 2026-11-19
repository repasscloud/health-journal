import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/security/journal_pin.dart';

class JournalPinForm extends StatefulWidget {
  const JournalPinForm({
    super.key,
    required this.enabled,
    required this.onSubmit,
    this.unlock = false,
  });

  final bool enabled, unlock;
  final Future<bool> Function(String current, String next) onSubmit;

  @override
  State<JournalPinForm> createState() => _JournalPinFormState();
}

class _JournalPinFormState extends State<JournalPinForm> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _remove = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final success = await widget.onSubmit(
        _current.text,
        widget.unlock || _remove ? '' : _next.text,
      );
      if (!mounted) return;
      if (success) {
        if (!widget.unlock) Navigator.of(context).pop();
        return;
      }
      _current.clear();
      setState(
        () =>
            _error = 'Incorrect PIN or too many attempts. Wait and try again.',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not access PIN settings. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool confirmation = false,
  }) => TextFormField(
    controller: controller,
    obscureText: true,
    enableSuggestions: false,
    autocorrect: false,
    enabled: !_busy,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(12),
    ],
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      if (!JournalPin.isValid(value ?? '')) return 'Enter 6 to 12 digits.';
      if (confirmation && value != _next.text) return 'PINs must match.';
      return null;
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.unlock ? 'Unlock journal' : 'Journal PIN'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    if (!widget.unlock)
                      const Text(
                        'The PIN locks the journal when you leave the app or after five minutes of inactivity. Keep it somewhere safe. A forgotten PIN cannot be recovered.',
                      ),
                    if (widget.enabled)
                      _field(
                        widget.unlock ? 'Journal PIN' : 'Current PIN',
                        _current,
                      ),
                    if (widget.enabled && !widget.unlock)
                      SwitchListTile(
                        value: _remove,
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _remove = value),
                        title: const Text('Remove PIN'),
                      ),
                    if (!widget.unlock && !_remove) ...[
                      _field('New PIN', _next),
                      _field('Confirm PIN', _confirm, confirmation: true),
                    ],
                    if (_error case final message?)
                      Semantics(liveRegion: true, child: Text(message)),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(
                        widget.unlock
                            ? 'Unlock'
                            : _remove
                            ? 'Remove PIN'
                            : 'Save PIN',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
