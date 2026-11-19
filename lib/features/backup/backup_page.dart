import 'package:flutter/material.dart';

import '../../platform/backup/journal_backup.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({
    super.key,
    required this.populated,
    required this.hasArchive,
    required this.busy,
    required this.message,
    required this.onClose,
    required this.onPick,
    required this.onDiscard,
    required this.onCreate,
    required this.onInspect,
    required this.onRestore,
  });

  final bool populated, hasArchive, busy;
  final String? message;
  final VoidCallback onClose, onPick, onDiscard;
  final Future<void> Function(String) onCreate;
  final Future<JournalBackupPreview> Function(String) onInspect;
  final Future<void> Function(JournalBackupPreview, bool replaceConfirmed)
  onRestore;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _creating = false, _working = false;
  String? _error;
  JournalBackupPreview? _preview;

  bool get _busy => widget.busy || _working;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _validateArchive() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter the password for this backup.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final preview = await widget.onInspect(_password.text);
      if (mounted) setState(() => _preview = preview);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not open the backup. Check its password and format.',
        );
      }
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _working = false);
      }
    }
  }

  Future<void> _create() async {
    final password = _password.text;
    if (password.trim().length < 12 || password.length > 1024) {
      setState(() => _error = 'Choose a password of at least 12 characters.');
      return;
    }
    if (password != _confirmPassword.text) {
      setState(() => _error = 'Passwords must match.');
      return;
    }
    _password.clear();
    _confirmPassword.clear();
    setState(() {
      _creating = false;
      _error = null;
    });
    await widget.onCreate(password);
  }

  void _discard() {
    _password.clear();
    _confirmPassword.clear();
    _confirmation.clear();
    setState(() {
      _preview = null;
      _creating = false;
      _error = null;
    });
    widget.onDiscard();
  }

  Widget _passwordField(String label, TextEditingController controller) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        maxLength: 1024,
        enabled: !_busy,
      );

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) widget.onClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Backup and restore'),
          leading: BackButton(onPressed: _busy ? null : widget.onClose),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.message case final message?)
                Semantics(liveRegion: true, child: Text(message)),
              if (_error case final error?)
                Semantics(liveRegion: true, child: Text(error)),
              if (_busy)
                const LinearProgressIndicator(
                  semanticsLabel: 'Backup operation in progress',
                ),
              const SizedBox(height: 12),
              if (preview != null) ...[
                Text(
                  'Backup preview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Created ${MaterialLocalizations.of(context).formatFullDate(preview.createdAt.toLocal())}',
                ),
                Text('${preview.counts['medications']} medications'),
                Text('${preview.counts['medication_events']} dose records'),
                Text('${preview.counts['symptom_entries']} symptoms'),
                Text('${preview.counts['measurements']} measurements'),
                const SizedBox(height: 16),
                if (widget.populated) ...[
                  const Text(
                    'Restoring replaces the entire journal on this device. You can cancel and create a backup of it first. Type REPLACE to confirm.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmation,
                    decoration: const InputDecoration(
                      labelText: 'Type REPLACE',
                    ),
                    onChanged: (_) => setState(() {}),
                    enabled: !_busy,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      _busy ||
                          (widget.populated && _confirmation.text != 'REPLACE')
                      ? null
                      : () => widget.onRestore(
                          preview,
                          _confirmation.text == 'REPLACE',
                        ),
                  child: Text(
                    widget.populated ? 'Replace journal' : 'Restore journal',
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _discard,
                  child: const Text('Cancel restore'),
                ),
              ] else if (widget.hasArchive) ...[
                _passwordField('Backup password', _password),
                FilledButton(
                  onPressed: _busy ? null : _validateArchive,
                  child: const Text('Preview backup'),
                ),
                TextButton(
                  onPressed: _busy ? null : _discard,
                  child: const Text('Cancel restore'),
                ),
              ] else if (_creating) ...[
                const Text(
                  'Use a long backup password and keep it safe. Existing files keep their original passwords. A forgotten password cannot be recovered.',
                ),
                const SizedBox(height: 12),
                _passwordField('Backup password', _password),
                _passwordField('Confirm backup password', _confirmPassword),
                FilledButton(
                  onPressed: _busy ? null : _create,
                  child: const Text('Choose where to save backup'),
                ),
                TextButton(
                  onPressed: _busy ? null : _discard,
                  child: const Text('Cancel backup'),
                ),
              ] else ...[
                const Text(
                  'A portable backup is encrypted with its own password. The file and that password are required to restore it.',
                ),
                const SizedBox(height: 16),
                if (widget.populated)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _creating = true),
                    child: const Text('Create encrypted backup'),
                  ),
                OutlinedButton(
                  onPressed: _busy ? null : widget.onPick,
                  child: const Text('Choose backup to restore'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
