import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../data/repositories/native_journal_repository.dart';
import '../data/schema/journal_database.dart';
import '../platform/security/native_store.dart';
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

class _AndroidJournalState extends State<AndroidJournal> {
  JournalDatabase? _database;
  NativeJournalRepository? _repository;
  bool _busy = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    await _prepare(() async {
      final database = await NativeStore.openJournal();
      if (!mounted) {
        await database.close();
        return;
      }
      _database = database;
      if (await database.select(database.profile).getSingleOrNull() != null) {
        _repository = await NativeJournalRepository.load(database);
      }
    });
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
    final database = _database;
    _database = null;
    if (database != null) unawaited(database.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    if (repository != null) {
      return JournalApp(environment: AppEnvironment.production(repository));
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
                                  unawaited(_open());
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
