import 'dart:async';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (details) {
    debugPrint('Flutter Error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error');
    return true;
  };

  final container = ProviderContainer();

  // Parallelize basic service initialization
  await Future.wait([dotenv.load(fileName: '.env'), StorageService.init()]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    UncontrolledProviderScope(container: container, child: const AllonbizApp()),
  );

  // Defer non-critical plugin setup until the first frame is visible.
  if (!kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(container.read(notificationServiceProvider).init());
    });
  }
}
