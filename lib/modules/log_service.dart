import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';

class _LogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    final LogService logInfo = event.origin.error as LogService;
    if (kDebugMode) event.lines.forEach(debugPrint);
    LogService._controller.add(
      logInfo..logLines = List<String>.unmodifiable(event.lines),
    );
  }
}

class LogService {
  static final _logger = Logger(
    filter: ProductionFilter(),
    output: _LogOutput(),
    printer: PrettyPrinter(
      stackTraceBeginIndex: 2,
      errorMethodCount: 2,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
  );
  static final _warnLogger = Logger(
    filter: ProductionFilter(),
    output: _LogOutput(),
    printer: PrettyPrinter(
      stackTraceBeginIndex: 2,
      lineLength: 24,
      printEmojis: false,
      noBoxingByDefault: false,
    ),
  );
  static final _controller = StreamController<LogService>.broadcast();

  static Stream<LogService> get stream => _controller.stream;

  static final ansiRegex = RegExp(r'\x1B\[[0-9;]*m');

  final String? msg;
  final String? errorMsg;
  final Object? errorObject;
  final Type? classType;
  final Object? instance;
  final DateTime time = DateTime.now();
  late final Level level;
  late final String levelTag;
  late final List<String> logLines;

  String get logString => logLines.join('\n').replaceAll(ansiRegex, '');

  LogService(
    this.msg, {
    this.errorMsg,
    this.errorObject,
    this.classType,
    this.instance,
  }) {
    unawaited(LogFileListener.init());
  }

  void t() => _log(Level.trace, '·');
  void d() => _log(Level.debug, '🐛');
  void i() => _log(Level.info, '💡');
  void w() => _log(Level.warning, '⚠️');
  void e() => _log(Level.error, '⛔');
  void f() => _log(.fatal, '👾');

  void _log(Level level, String levelTag) {
    this.level = level;
    this.levelTag = levelTag;
    final String where = <String>[
      if (classType != null) 'class<$classType>',
      if (instance != null) 'instance<$instance>',
    ].join(', ');
    return (level < .warning ? _logger : _warnLogger).log(
      level,
      <String>[if (where.isNotEmpty) where, ?Utils.noEmptyStr(msg)].join('\n'),
      time: time,
      error: this,
    );
  }

  @override
  String toString() {
    final String? errorObjectString = errorObject?.toString();
    return <String>[
      '[$levelTag ${level.name.toUpperCase()} ${time.toLocal()}]',
      ?Utils.noEmptyStr(errorMsg),
      ?Utils.noEmptyStr(errorObjectString),
    ].join('\n');
  }
}
