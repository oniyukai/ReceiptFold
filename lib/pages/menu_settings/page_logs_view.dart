import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const String _separatorOfLog = '‖§SEPARATOR_OF_LOG¶';
final RegExp _ansiRegex = RegExp(r'\x1B\[[0-9;]*m');

class _LogOutput extends LogOutput {
  @override
  void output(event) {
    final LogService logInfo = event.origin.error as LogService;
    if (kDebugMode) event.lines.forEach(debugPrint);
    LogService._controller.add(logInfo..logLines = List.unmodifiable(event.lines));
  }
}

class LogService {
  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    output: _LogOutput(),
    printer: PrettyPrinter(
      stackTraceBeginIndex: 2,
      errorMethodCount: 2,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
  );
  static final Logger _warnLogger = Logger(
    filter: ProductionFilter(),
    output: _LogOutput(),
    printer: PrettyPrinter(
      stackTraceBeginIndex: 2,
      printEmojis: false,
      noBoxingByDefault: false,
    ),
  );
  static final StreamController<LogService> _controller = .broadcast();

  static Stream<LogService> get stream => _controller.stream;

  final String? msg;
  final String? errorMsg;
  final Object? errorObject;
  final Type? classType;
  final Object? instance;
  final DateTime time = .now();
  late final Level level;
  late final String levelTag;
  late final List<String> logLines;

  String get logString => logLines.join('\n').replaceAll(_ansiRegex, '');

  LogService(this.msg, {
    this.errorMsg,
    this.errorObject,
    this.classType,
    this.instance,
  }) {
    unawaited(_LogFileListener._file);
  }

  void t() => _log(.trace, '·');
  void d() => _log(.debug, '🐛');
  void i() => _log(.info, '💡');
  void w() => _log(.warning, '⚠️');
  void e() => _log(.error, '⛔');
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
      <String>[
        if (where.isNotEmpty) where,
        if (msg != null && msg!.isNotEmpty) msg!,
      ].join('\n'),
      time: time,
      error: this,
    );
  }

  @override
  String toString() {
    final String? errorObjectString = errorObject?.toString();
    return <String>[
      '[$levelTag ${level.name.toUpperCase()} ${time.toLocal()}]',
      if (errorMsg != null && errorMsg!.isNotEmpty) errorMsg!,
      if (errorObjectString != null && errorObjectString.isNotEmpty) errorObjectString,
    ].join('\n');
  }
}

final class _LogFileListener {
  const _LogFileListener._();

  static IOSink? _ioSink;
  static Timer? _flushTimer;
  static Future<void> _ioTask = Future.value();
  static final List<String> _logQueue = [];
  static final Future<File> _file = () async {
    final Directory dir = await getApplicationSupportDirectory();
    final File file = File(p.join(dir.path, 'logs.txt'));
    LogService.stream
        .where((e) => e.level >= .info)
        .map((log) => log.logLines)
        .listen(_enqueue);
    return file;
  }();

  static Future<IOSink> _getSink() async =>
      _ioSink ?? (_ioSink = (await _file).openWrite(mode: .append));

  static Future<void> _disposeSink() async {
    await _ioSink?.flush();
    await _ioSink?.close();
    _ioSink = null;
  }

  static void _enqueue(List<String> lines) {
    _logQueue..addAll(lines)..add(_separatorOfLog);

    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(seconds: 2), () {
      if (_logQueue.isEmpty) return;
      final String contents = _logQueue.join('\n').replaceAll(_ansiRegex, '');
      _logQueue.clear();
      _ioTask = _ioTask.then((_) async {
        final IOSink sink = await _getSink();
        sink.writeln(contents);
        await sink.flush();
      });
    });
  }

  static Future<String> readLogs() async {
    String contents = '';
    await (_ioTask = _ioTask.then((_) async {
      final File file = await _file;
      if (await file.exists()) contents = await file.readAsString();
    }));
    return contents;
  }

  static Future<void> replaceLogs(String contents) =>
      _ioTask = _ioTask.then((_) async {
        await _disposeSink();
        await (await _file).writeAsString(contents, flush: true);
      });
}

class PageLogsView extends StatefulWidget {
  const PageLogsView({super.key});

  @override
  State<PageLogsView> createState() => _PageLogsViewState();
}

class _PageLogsViewState extends State<PageLogsView> {
  List<String>? _formattedLogs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pressRefresh());
  }

  Future<void> _pressRefresh() async {
    setState(() => _formattedLogs = null);
    final String contents = await _LogFileListener.readLogs();
    List<String> formattedLogs = contents.split(_separatorOfLog).reversed.where((s) => s.trim().isNotEmpty).toList();
    if (formattedLogs.length >= 1024) {
      formattedLogs = formattedLogs.sublist(0, 512);
      await _LogFileListener.replaceLogs('${formattedLogs.reversed.join(_separatorOfLog)}\n');
    }
    setState(() => _formattedLogs = formattedLogs);
  }

  Future<ShareResult> _pressShare() async => await SharePlus.instance.share(
    ShareParams(
      files: [XFile((await _LogFileListener._file).path)],
    ),
  );

  Future<void> _pressDelete() async {
    setState(() => _formattedLogs = null);
    await _LogFileListener.replaceLogs('');
    await _pressRefresh();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('除錯日誌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _pressDelete,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _pressShare,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _pressDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            children: [
              if (_formattedLogs == null) CircularProgressIndicator(),
              if (_formattedLogs != null) SelectableText(_formattedLogs!.join()),
            ],
          ),
        ),
      ),
    );
  }
}
