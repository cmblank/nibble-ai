import 'dart:async';

import 'package:app_links/app_links.dart';

/// Lightweight helper to log deep links for debugging.
class DeepLinkLogger {
  static StreamSubscription<Uri>? _sub;

  static Future<void> init() async {
    try {
      final appLinks = AppLinks();

      // Log the initial deep link if the app was started by one
  final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        // ignore: avoid_print
        print('[DeepLink] initial: $initialUri');
      }

      // Listen for subsequent incoming links while app is running
      _sub?.cancel();
  _sub = appLinks.uriLinkStream.listen(
        (uri) {
          // ignore: avoid_print
          print('[DeepLink] incoming: $uri');
        },
        onError: (e) {
          // ignore: avoid_print
          print('[DeepLink] error: $e');
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[DeepLink] init error: $e');
    }
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
