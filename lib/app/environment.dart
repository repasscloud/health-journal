import '../data/demo/demo_repository.dart';
import '../data/repositories/journal_repository.dart';

final class AppEnvironment {
  AppEnvironment.demo({bool richFixture = true})
    : repository = DemoRepository(richFixture: richFixture),
      isDemo = true,
      isReview = false;
  AppEnvironment.fictionalReview()
    : repository = DemoRepository(richFixture: true),
      isDemo = true,
      isReview = true;
  // Fail closed until native encrypted storage passes the release proof.
  const AppEnvironment.nativePending()
    : repository = null,
      isDemo = false,
      isReview = false;
  final JournalRepository? repository;
  final bool isDemo;
  final bool isReview;
}
