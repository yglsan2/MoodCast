import 'package:flutter/foundation.dart';

/// Logs MoodSafe (Mode Diwall / diffusion / Lien Sœurs / SMS).
class MoodSafeLog {
  MoodSafeLog._();

  static const String _tag = 'MoodSafe';

  static void info(String message, [Object? detail]) {
    if (detail == null) {
      debugPrint('[$_tag] $message');
    } else {
      debugPrint('[$_tag] $message | $detail');
    }
  }

  static void warn(String message, [Object? error]) {
    debugPrint('[$_tag][WARN] $message${error != null ? ' | $error' : ''}');
  }

  static void error(String message, Object error, [StackTrace? stack]) {
    debugPrint('[$_tag][ERROR] $message | $error');
    if (stack != null) {
      debugPrint('[$_tag][ERROR] $stack');
    }
  }
}
