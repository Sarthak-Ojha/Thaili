import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Global test configuration hook for Flutter tests.
///
/// Automatically initializes the sqflite_common_ffi SQLite FFI engine
/// before any unit, widget, or integration test runs on the host desktop.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
