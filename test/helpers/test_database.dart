import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lumara_indigenas/data/local/database/app_database.dart';

/// Test Database Helper
/// Creates in-memory database for testing without requiring native SQLite
AppDatabase createTestDatabase() {
  // Use in-memory database for tests
  return AppDatabase.forTesting(
    NativeDatabase.memory(logStatements: false),
  );
}

/// Close and cleanup test database
Future<void> closeTestDatabase(AppDatabase db) async {
  await db.close();
}
