import '../data/demo/demo_repository.dart';
import '../data/repositories/journal_repository.dart';

final class AppEnvironment {
  AppEnvironment.demo() : repository = DemoRepository(), isDemo = true;
  // Fail closed until native encrypted storage passes the release proof.
  const AppEnvironment.nativePending() : repository = null, isDemo = false;
  final JournalRepository? repository;
  final bool isDemo;
}
