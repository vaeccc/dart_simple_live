import 'package:logger/logger.dart';

import 'http_log_sanitizer.dart';

enum RequestLogType { all, short, none }

class CoreLog {
  static bool enableLog = true;
  static RequestLogType requestLogType = RequestLogType.all;
  static Function(Level, String)? onPrintLog;

  static Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static String sanitize(Object? value) =>
      HttpLogSanitizer.maskText(value?.toString() ?? '');

  static void d(String message) => _write(Level.debug, message);
  static void i(String message) => _write(Level.info, message);
  static void w(String message) => _write(Level.warning, message);

  static void e(String message, StackTrace stackTrace) {
    if (!enableLog) return;
    final safeMessage = sanitize(message);
    onPrintLog?.call(Level.error, safeMessage);
    if (onPrintLog == null) {
      logger.e("${DateTime.now()}\n$safeMessage", stackTrace: stackTrace);
    }
  }

  static void error(Object? error) {
    if (!enableLog) return;
    final safeMessage = sanitize(error);
    onPrintLog?.call(Level.error, safeMessage);
    if (onPrintLog == null) {
      logger.e(
        "${DateTime.now()}\n$safeMessage",
        error: safeMessage,
        stackTrace: error is Error ? error.stackTrace : StackTrace.current,
      );
    }
  }

  static void _write(Level level, String message) {
    if (!enableLog) return;
    final safeMessage = sanitize(message);
    onPrintLog?.call(level, safeMessage);
    if (onPrintLog != null) return;
    if (level == Level.debug) {
      logger.d("${DateTime.now()}\n$safeMessage");
    } else if (level == Level.warning) {
      logger.w("${DateTime.now()}\n$safeMessage");
    } else {
      logger.i("${DateTime.now()}\n$safeMessage");
    }
  }
}
