import 'dart:io';

enum LogLevel {
  none,
  develop,
  production,
}

class Logger<T> {
  final LogLevel logLevel;

  const Logger(this.logLevel);

  void info(String message) {
    if (logLevel == LogLevel.none) {
      return;
    }

    if (logLevel == LogLevel.production) {
      return;
    }

    stdout.writeln('${_getDateStr()} [$T] INF: $message');
  }

  void warning(String message) {
    if (logLevel == LogLevel.none) {
      return;
    }

    if (logLevel == LogLevel.production) {
      return;
    }

    stdout.writeln('${_getDateStr()} [$T] WRN: $message');
  }

  void trace(String message) {
    stdout.writeln('${_getDateStr()} [$T] TRC: $message');
  }

  void error(String message, Object error) {
    if (logLevel == LogLevel.none) {
      return;
    }

    stderr.writeln('${_getDateStr()} [$T] ERR: $message');
    stderr.writeln(error);
  }

  String _getDateStr() {
    final now = DateTime.now();

    String pad(int num) {
      return num.toString().padLeft(2, '0');
    }

    return '${pad(now.month)}-${pad(now.day)}-${now.year} ${pad(now.hour)}:${pad(now.minute)}:${pad(now.second)}';
  }
}
