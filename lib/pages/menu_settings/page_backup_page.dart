import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
import 'package:receipt_fold/pages/widget/expandable_card.dart';
import 'package:receipt_fold/pages/widget/required_text_field.dart';

class PageBackupPage extends StatefulWidget {
  const PageBackupPage({super.key});

  @override
  State<StatefulWidget> createState() => _PageBackupPageState();
}

class _PageBackupPageState extends State<PageBackupPage> {
  final List<LogService> _logs = [];
  late final StreamSubscription<LogService> _logSubscription;

  @override
  void initState() {
    super.initState();
    _logSubscription = LogService.stream.where((e) => e.level >= .debug).listen((data) {
      setState(() {
        _logs.add(data);
      });
    });
  }
  
  @override
  void dispose() {
    super.dispose();
    _logSubscription.cancel();
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('備份與同步'),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            padding: const .fromLTRB(16.0, 0.0, 16.0, 16.0),
            children: [
              ExpandableCard(
                iconData: Icons.snippet_folder,
                text: '本地動作',
                expandedChild: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload),
                      title: Text('pushForce'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: Text('pushMerge'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: Text('pullForce'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text('pullMerge'),
                      onTap: () => Utils.showToast('pullMerge'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text('syncMerge'),
                      onTap: () => Utils.showWidgetToast(Text('syncMerge')),
                    ),
                  ],
                ),
              ),
              ExpandableCard(
                iconData: Icons.cloud_sync,
                text: 'WebDAV 動作',
                expandedChild: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload),
                      title: Text('pushForce'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: Text('pushMerge'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: Text('pullForce'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text('pullMerge'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text('syncMerge'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text('啟用定期同步'),
                    ),
                  ],
                ),
              ),
              ExpandableCard(
                iconData: Icons.add_to_drive,
                text: 'WebDAV 參數',
                expandedChild: Column(
                  children: [
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text('URL'),
                    ),
                    RequiredTextField(
                      name: 'url',
                      // initialValue: initialAccount,
                    ),
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text('User'),
                    ),
                    RequiredTextField(
                      name: 'user',
                      // initialValue: initialPassword,
                    ),
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text('Password'),
                    ),
                    RequiredTextField(
                      name: 'password',
                      // initialValue: initialPassword,
                      type: FieldType.password,
                    ),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('保存並嘗試連線'),
                    ),
                  ],
                ),
              ),
              ExpandableCard(
                iconData: Icons.terminal,
                text: '即時日誌',
                expandedChild: Column(
                  children: [
                    for (final log in _logs)
                      SelectableText(log.logString),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}