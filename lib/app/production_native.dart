import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositories/native_journal_repository.dart';
import '../data/schema/journal_database.dart';
import '../domain/reminder_plan.dart';
import '../features/backup/backup_page.dart';
import '../features/reminder_settings.dart';
import '../features/reports/journal_csv.dart';
import '../features/reports/journal_export.dart';
import '../features/security_pin_form.dart';
import '../platform/backup/journal_backup.dart';
import '../platform/security/journal_pin.dart';
import '../platform/security/native_store.dart';
import '../platform/security/secure_installation_key_store.dart';
import 'environment.dart';
import 'journal_app.dart';
import 'journal_theme.dart';

// Android hardware evidence is recorded in IMPLEMENTATION_STATUS.md.
// iOS requires its own physical-device evidence before enabling setup.
Widget productionApp() => Platform.isAndroid
    ? const AndroidJournal()
    : const JournalApp(environment: AppEnvironment.nativePending());

class AndroidJournal extends StatefulWidget {
  const AndroidJournal({super.key});

  @override
  State<AndroidJournal> createState() => _AndroidJournalState();
}

class _AndroidJournalState extends State<AndroidJournal>
    with WidgetsBindingObserver {
  static const _documents = MethodChannel('health_journal/documents');
  static const _backup = JournalBackup();
  bool _backupBusy = false, _backupOpen = false;
  var _journalNavigator = GlobalKey<NavigatorState>();
  final _backupView =
      ValueNotifier<({bool busy, bool hasArchive, String? message})>((
        busy: false,
        hasArchive: false,
        message: null,
      ));
  Uint8List? _backupBytes;
  String? _backupMessage;
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _exporting = false;
  String? _exportResult;
  final _pin = JournalPin(const SecureInstallationKeyStore.journalPin());
  Timer? _idle, _reminderRefresh;
  bool _pinEnabled = false;
  bool _locked = false;
  int _lockEpoch = 0;
  JournalDatabase? _database;
  NativeJournalRepository? _repository;
  bool _busy = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    unawaited(_checkPin());
  }

  Future<void> _checkPin() async {
    await _prepare(() async {
      _pinEnabled = await _pin.isEnabled();
      _locked = _pinEnabled;
      if (!_locked) await _openDatabase();
    });
  }

  bool _onKey(KeyEvent event) {
    _resetIdle();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _queueReminders();
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _lock();
    }
  }

  Widget _backupPage(BuildContext context) {
    _backupOpen = true;
    return ValueListenableBuilder(
      valueListenable: _backupView,
      builder: (context, view, _) => BackupPage(
        populated: _repository != null,
        busy: view.busy,
        hasArchive: view.hasArchive,
        message: view.message,
        onClose: () {
          _backupOpen = false;
          _discardBackup();
        },
        onPick: _pickBackup,
        onDiscard: _discardBackup,
        onCreate: _createBackup,
        onInspect: _inspectBackup,
        onRestore: _restoreBackup,
      ),
    );
  }

  void _refreshBackup() {
    _backupView.value = (
      busy: _backupBusy,
      hasArchive: _backupBytes != null,
      message: _backupMessage,
    );
  }

  void _discardBackup() {
    _backupBytes = null;
    _backupMessage = null;
    _refreshBackup();
  }

  Future<void> _pickBackup() async {
    if (_backupBusy || _locked) return;
    _backupBusy = true;
    _backupMessage = null;
    _refreshBackup();
    try {
      final bytes = await _documents.invokeMethod<Uint8List>('openBackup');
      if (!mounted) return;
      // Platform replies may expose a read-only view. The archive is ciphertext.
      _backupBytes = bytes;
    } catch (_) {
      _backupMessage = 'Could not read the chosen backup.';
    } finally {
      _backupBusy = false;
      if (mounted) _refreshBackup();
    }
  }

  Future<JournalBackupPreview> _inspectBackup(String password) async {
    final bytes = _backupBytes;
    if (_locked || _backupBusy || bytes == null) {
      throw StateError('No backup can be opened.');
    }
    _backupBusy = true;
    _backupMessage = null;
    _refreshBackup();
    try {
      return await _backup.inspect(bytes, password);
    } finally {
      _backupBusy = false;
      if (mounted) _refreshBackup();
    }
  }

  Future<void> _createBackup(String password) async {
    final db = _database;
    if (_locked || _backupBusy || db == null) return;
    _backupBusy = true;
    _backupMessage = null;
    _refreshBackup();
    Uint8List? bytes;
    try {
      await _repository?.pendingWrites;
      bytes = await _backup.create(db, password);
      if (!mounted || _locked) return;
      final saved = await _documents.invokeMethod<bool>('saveBackup', bytes);
      if (saved == true) {
        _backupMessage = 'Backup saved to the chosen location.';
      }
    } catch (_) {
      _backupMessage = 'Could not save the backup.';
    } finally {
      bytes?.fillRange(0, bytes.length, 0);
      _backupBusy = false;
      if (mounted) _refreshBackup();
    }
  }

  Future<void> _restoreBackup(
    JournalBackupPreview preview,
    bool replaceConfirmed,
  ) async {
    final db = _database;
    if (_locked || _backupBusy || db == null) return;
    _backupBusy = true;
    _backupMessage = null;
    _refreshBackup();
    var committed = false;
    try {
      await _repository?.pendingWrites;
      if (!mounted || _locked) return;
      await _backup.restoreInto(
        db,
        preview,
        replaceConfirmed: replaceConfirmed,
      );
      committed = true;
      final repository = await NativeJournalRepository.load(db);
      if (!mounted) return;
      setState(() {
        _repository = repository;
        _journalNavigator = GlobalKey<NavigatorState>();
        _exportResult = 'Journal restored.';
        _backupOpen = false;
        _backupBytes = null;
      });
      _queueReminders();
      _showExportResult();
    } catch (_) {
      if (committed) {
        if (mounted) {
          setState(() {
            _repository = null;
            _database = null;
            _failed = true;
            _backupOpen = false;
            _backupBytes = null;
          });
          await db.close();
        }
      } else {
        _backupMessage =
            'Could not restore the backup. The current journal is unchanged.';
      }
    } finally {
      _backupBusy = false;
      if (mounted) _refreshBackup();
    }
  }

  Future<void> _exportCsv() async {
    final repository = _repository;
    if (_exporting || _locked || repository == null) return;
    setState(() => _exporting = true);
    final bytes = journalCsv(repository);
    try {
      final saved = await _documents.invokeMethod<bool>('saveCsv', bytes);
      _exportResult = saved == true
          ? 'CSV saved to the chosen location.'
          : null;
    } catch (_) {
      _exportResult = 'Could not save the CSV to the chosen location.';
    } finally {
      bytes.fillRange(0, bytes.length, 0);
      if (mounted) setState(() => _exporting = false);
      _showExportResult();
    }
  }

  void _showExportResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final result = _exportResult;
      final messenger = _messenger.currentState;
      if (!mounted || _locked || result == null || messenger == null) return;
      _exportResult = null;
      messenger.showSnackBar(SnackBar(content: Text(result)));
    });
  }

  void _queueReminders() {
    _reminderRefresh?.cancel();
    if (!mounted || _repository == null) return;
    _reminderRefresh = Timer(const Duration(milliseconds: 250), () async {
      final repository = _repository;
      if (!mounted || repository == null) return;
      final plan = planMedicationReminders(
        now: DateTime.now(),
        medications: repository.medications,
        regimens: repository.regimens,
        enabledRegimenIds: {
          for (final regimen in repository.regimens)
            if (regimen.reminderEnabled) regimen.id,
        },
        administrations: repository.administrations,
      );
      try {
        await journalRemindersChannel.invokeMethod<void>('replace', [
          for (final slot in plan) slot.at.millisecondsSinceEpoch,
        ]);
      } on PlatformException {
        // System scheduling is best effort. The next resume or edit retries.
      }
    });
  }

  void _lock() {
    if (!_pinEnabled || !mounted) return;
    _lockEpoch++;
    _idle?.cancel();
    if (!_locked) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _locked = true);
    }
  }

  void _resetIdle() {
    if (!_pinEnabled || _locked) return;
    _idle?.cancel();
    _idle = Timer(const Duration(minutes: 5), _lock);
  }

  Future<bool> _unlock(String current, String _) async {
    final epoch = _lockEpoch;
    if (!await _pin.verify(current) || !mounted || epoch != _lockEpoch) {
      return false;
    }
    setState(() {
      _locked = false;
      _failed = false;
      _busy = _database == null;
    });
    if (_database == null) await _prepare(_openDatabase);
    _resetIdle();
    if (_backupOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _locked || !_backupOpen) return;
        _journalNavigator.currentState?.push<void>(
          MaterialPageRoute(builder: _backupPage),
        );
      });
    }
    _showExportResult();
    return true;
  }

  Future<bool> _configurePin(String current, String next) async {
    if (!await _pin.configure(current: current, next: next)) return false;
    if (!mounted) return true;
    setState(() => _pinEnabled = next.isNotEmpty);
    _idle?.cancel();
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _lock();
    } else {
      _resetIdle();
    }
    return true;
  }

  Future<void> _openDatabase() async {
    final database = await NativeStore.openJournal();
    if (!mounted) {
      await database.close();
      return;
    }
    _database = database;
    if (await database.select(database.profile).getSingleOrNull() != null) {
      _repository = await NativeJournalRepository.load(database);
      _queueReminders();
    }
  }

  Future<void> _startFresh() async {
    setState(() => _busy = true);
    await _prepare(() async {
      final database = _database!;
      await NativeStore.initializeProfile(database);
      _repository = await NativeJournalRepository.load(database);
      _queueReminders();
    });
  }

  Future<void> _prepare(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      final database = _database;
      _database = null;
      if (database != null) await database.close();
      _failed = true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    _reminderRefresh?.cancel();
    _backupBytes = null;
    _backupView.dispose();
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    final database = _database;
    _database = null;
    if (database != null) unawaited(database.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_locked && !_busy) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: journalTheme(Brightness.light),
        darkTheme: journalTheme(Brightness.dark),
        key: const ValueKey('locked'),
        home: JournalPinForm(enabled: true, unlock: true, onSubmit: _unlock),
      );
    }
    final repository = _repository;
    if (!_locked && repository != null) {
      return Listener(
        onPointerDown: (_) => _resetIdle(),
        onPointerMove: (_) => _resetIdle(),
        onPointerSignal: (_) => _resetIdle(),
        child: JournalApp(
          key: ObjectKey(repository),
          environment: AppEnvironment.production(repository),
          onJournalChanged: _queueReminders,
          messengerKey: _messenger,
          navigatorKey: _journalNavigator,
          exportSettings: (_) => JournalExport(onExport: _exportCsv),
          backupSettings: _backupPage,
          reminderSettings: (_) =>
              ReminderSettings(onPermissionChanged: _queueReminders),
          privacySettings: (_) =>
              JournalPinForm(enabled: _pinEnabled, onSubmit: _configurePin),
        ),
      );
    }
    return MaterialApp(
      key: ValueKey(_failed),
      title: 'Health Journal',
      debugShowCheckedModeBanner: false,
      theme: journalTheme(Brightness.light),
      darkTheme: journalTheme(Brightness.dark),
      home: Scaffold(
        appBar: AppBar(title: const Text('Health Journal')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _busy
                  ? const CircularProgressIndicator(
                      semanticsLabel: 'Opening encrypted journal',
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        Text(
                          _failed
                              ? 'Journal unavailable'
                              : 'Your private journal',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          _failed
                              ? 'The encrypted journal could not be opened. Unlock your device and try again.'
                              : 'Your records stay on this device in encrypted storage. Health Journal records what you report and does not provide medical advice.',
                        ),
                        FilledButton(
                          onPressed: _failed
                              ? () {
                                  setState(() {
                                    _failed = false;
                                    _busy = true;
                                  });
                                  unawaited(_checkPin());
                                }
                              : _startFresh,
                          child: Text(_failed ? 'Try again' : 'Start fresh'),
                        ),
                        if (!_failed)
                          Builder(
                            builder: (context) => OutlinedButton(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(builder: _backupPage),
                              ),
                              child: const Text('Restore existing backup'),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
