import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String msg)  => kDebugMode ? debugPrint('[INFO]  $msg') : null;
  static void error(String msg) => kDebugMode ? debugPrint('[ERROR] $msg') : null;
  static void warn(String msg)  => kDebugMode ? debugPrint('[WARN]  $msg') : null;
}
