/// Logging service for the Tailwind CSS plugin.
library;

import 'package:lumide_tailwindcss/src/constants.dart';

class LogService {
  LogService(this._logFn);

  final void Function(String) _logFn;

  void info(String message) {
    _logFn('[$pluginName] [INFO] $message');
  }

  void warning(String message) {
    _logFn('[$pluginName] [WARN] $message');
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final buffer = StringBuffer('[$pluginName] [ERROR] $message');
    if (error case final err?) {
      buffer.write(': $err');
    }
    if (stackTrace case final trace?) {
      buffer.write('\n$trace');
    }
    _logFn(buffer.toString());
  }
}
