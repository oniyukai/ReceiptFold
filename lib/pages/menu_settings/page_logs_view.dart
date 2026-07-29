import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/log_service.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';
import 'package:share_plus/share_plus.dart';

const String _separatorOfLog = '‖§SEPARATOR_OF_LOG¶';

abstract final class LogFileListener {
  static IOSink? _ioSink;
  static Timer? _flushTimer;
  static Future<void> _ioTask = Future.value();
  static final _logQueue = <String>[];
  static final Future<File> _file = () async {
    final Directory dir = await getApplicationSupportDirectory();
    final File file = File(p.join(dir.path, 'logs.txt'));
    LogService.stream
        .where((e) => e.level >= Level.info)
        .map((log) => log.logLines)
        .listen(_enqueue);
    return file;
  }();

  static Future<void> init() async {
    await _file;
  }

  static Future<IOSink> _getSink() async =>
      _ioSink ?? (_ioSink = (await _file).openWrite(mode: FileMode.append));

  static Future<void> _disposeSink() async {
    await _ioSink?.flush();
    await _ioSink?.close();
    _ioSink = null;
  }

  static void _enqueue(List<String> lines) {
    _logQueue
      ..addAll(lines)
      ..add(_separatorOfLog);

    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(seconds: 2), () {
      if (_logQueue.isEmpty) return;
      final String contents = _logQueue
          .join('\n')
          .replaceAll(LogService.ansiRegex, '');
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
  final ScrollController _scrollController = ScrollController();
  List<String>? _formattedLogs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pressRefresh());
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> _pressRefresh() async {
    setState(() => _formattedLogs = null);
    final String contents = await LogFileListener.readLogs();
    List<String> formattedLogs = contents
        .split(_separatorOfLog)
        .reversed
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (formattedLogs.length >= 1024) {
      formattedLogs = formattedLogs.sublist(0, 512);
      await LogFileListener.replaceLogs(
        '${formattedLogs.reversed.join('\n$_separatorOfLog\n')}\n$_separatorOfLog\n',
      );
    }
    setState(() => _formattedLogs = formattedLogs);
  }

  Future<ShareResult> _pressShare() async => await SharePlus.instance.share(
    ShareParams(files: [XFile((await LogFileListener._file).path)]),
  );

  Future<void> _pressDelete() => OverlayShow.dialog(
    context: context,
    title: DictKey.backupDeleteLog.s,
    content: Text(DictKey.backupSureDeleteLog.s),
    actions: [
      TextButton(
        onPressed: () async {
          Navigator.pop(context);
          setState(() => _formattedLogs = null);
          await LogFileListener.replaceLogs('');
          await _pressRefresh();
        },
        child: Text(DictKey.commonUiDelete.s),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DictKey.settingOptionDebugLog.s),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _pressRefresh),
          IconButton(icon: const Icon(Icons.share), onPressed: _pressShare),
          IconButton(icon: const Icon(Icons.delete), onPressed: _pressDelete),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            children: [
              if (_formattedLogs == null) const CircularProgressIndicator(),
              if (_formattedLogs != null)
                SelectableText(_formattedLogs!.join('\n')),
            ],
          ),
        ),
      ),
    );
  }
}
