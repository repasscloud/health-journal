import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositories/native_journal_repository.dart';
import '../data/schema/journal_database.dart';
import '../features/security_pin_form.dart';
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
  final _pin = JournalPin(const SecureInstallationKeyStore.journalPin());
  Timer? _idle;
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
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _lock();
    }
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
    }
  }

  Future<void> _startFresh() async {
    setState(() => _busy = true);
    await _prepare(() async {
      final database = _database!;
      await NativeStore.initializeProfile(database);
      _repository = await NativeJournalRepository.load(database);
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
          environment: AppEnvironment.production(repository),
          privacySettings: (_) =>
              JournalPinForm(enabled: _pinEnabled, onSubmit: _configurePin),
        ),
      );
    }
    return MaterialApp(
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
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
