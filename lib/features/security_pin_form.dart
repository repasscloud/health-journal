import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/security/journal_pin.dart';

class JournalPinForm extends StatefulWidget {
  const JournalPinForm({
    super.key,
    required this.enabled,
    required this.onSubmit,
    this.unlock = false,
    this.onErase,
    this.onEraseWithPin,
  });

  final bool enabled, unlock;
  final Future<bool> Function()? onErase;
  final Future<bool> Function(String current)? onEraseWithPin;
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

  Future<void> _confirmErase() async {
    final eraseWithPin = widget.onEraseWithPin;
    final erase = widget.onErase;
    if (_busy || (erase == null && eraseWithPin == null)) return;
    final current = _current.text;
    if (eraseWithPin != null &&
        widget.enabled &&
        !JournalPin.isValid(current)) {
      setState(() => _error = 'Enter your current PIN to erase app data.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    var confirmed = false;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          scrollable: true,
          title: const Text('Erase Health Journal data?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const Text(
                'This permanently erases your local journal, PIN, settings and reminders. Exported PDFs, CSV files and backups, including copies held by document providers, stay at their chosen locations. Backups still require their original password.',
              ),
              const Text(
                'Type ERASE to confirm. Reopen the app to start fresh or restore a backup.',
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Type ERASE'),
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (value) =>
                    updateDialog(() => confirmed = value == 'ERASE'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: confirmed
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('Erase app data'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (approved == true) {
      try {
        final accepted = eraseWithPin == null
            ? await erase!()
            : await eraseWithPin(current);
        if (accepted) return; // Android closes the app to clear its data.
      } catch (_) {
        // The journal stays locked when Android cannot start the reset.
      }
      if (!mounted) return;
      _current.clear();
      _error = eraseWithPin != null && widget.enabled
          ? 'Could not erase app data. Check your PIN or wait and try again.'
          : 'Could not erase app data. Try again.';
    }
    setState(() => _busy = false);
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
                    if (!widget.unlock && widget.onEraseWithPin != null)
                      TextButton(
                        onPressed: _busy ? null : _confirmErase,
                        child: const Text('Delete all local data'),
                      ),
                    if (widget.unlock && widget.onErase != null)
                      TextButton(
                        onPressed: _busy ? null : _confirmErase,
                        child: const Text('Forgot PIN?'),
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
