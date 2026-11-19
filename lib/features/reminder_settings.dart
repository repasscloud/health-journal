import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const journalRemindersChannel = MethodChannel('health_journal/reminders');

class ReminderSettings extends StatefulWidget {
  const ReminderSettings({super.key, required this.onPermissionChanged});

  final VoidCallback onPermissionChanged;

  @override
  State<ReminderSettings> createState() => _ReminderSettingsState();
}

class _ReminderSettingsState extends State<ReminderSettings> {
  bool _enabled = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _run('enabled');
  }

  Future<void> _run(String method) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await journalRemindersChannel.invokeMethod<bool>(method);
      if (!mounted) return;
      setState(() {
        _enabled = result == true;
        if (method == 'test' && _enabled) {
          _message = 'Test reminder sent.';
        } else if (method != 'enabled' && !_enabled) {
          _message = 'Allow Health Journal notifications in Android settings.';
        }
      });
      if (method == 'request') widget.onPermissionChanged();
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not access Android notifications.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reminders')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _enabled ? 'Notifications are allowed.' : 'Notifications are off.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Turn on local reminders for each scheduled regimen. Reminders are best effort and may be delayed. Open the journal after a restart or a clock change to refresh them.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Notifications omit medication details. A reminder or tap never records a dose.',
          ),
          const SizedBox(height: 16),
          if (_message case final message?)
            Semantics(liveRegion: true, child: Text(message)),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(_enabled ? 'test' : 'request'),
              child: Text(
                _enabled ? 'Send test reminder' : 'Allow notifications',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
