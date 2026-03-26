import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_db.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  try {
    final db = AppDatabase();
    ref.onDispose(() => db.close());
    return db;
  } catch (e, st) {
    debugPrint('DB INIT ERROR: $e');
    debugPrintStack(stackTrace: st);
    rethrow;
  }
});
