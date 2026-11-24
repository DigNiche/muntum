import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Uses an isolated in-memory secure store, never the device's real keychain.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FlutterSecureStorage.setMockInitialValues({});
  await testMain();
}
