import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Runs CPU-heavy sync work off the main isolate where supported.
Future<T> runInBackground<T>(T Function() computation) {
  if (kIsWeb) {
    return Future<T>.sync(computation);
  }

  return Isolate.run<T>(computation);
}
