import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/modules/secure_prefs.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
import 'package:receipt_fold/pages/widget/expandable_card.dart';
import 'package:receipt_fold/pages/widget/my_text_field.dart';
import 'package:path/path.dart' as p;

enum DBActions {
  pushForce,
  push,
  pullForce,
  pull,
  sync,
}

class PageBackupPage extends StatefulWidget {
  const PageBackupPage({super.key});

  static Timer? _webDAVSyncFirstTimer;
  static int _lastTimeWebDAVSWork = 0;
  static WebDAV? _webDAV;

  static Future<void> setWebDAV() async {
    _webDAVSyncFirstTimer?.cancel();
    final String? url = await SecurePrefs.webDAVUrl.read();
    final String? user = await SecurePrefs.webDAVUser.read();
    final String? password = await SecurePrefs.webDAVPassword.read();
    if (url == null || user == null || password == null) return;
    try {
      _webDAV = null;
      _webDAV = await WebDAV.connect(url, user, password);
      if (await PrefsEnum.isAutoWebDAVSync.get()) {
        _webDAVSyncFirstTimer = Timer(const Duration(seconds: 4), () => _webDavAction(.sync));
      }
    } catch (e) {
      LogService('setWebDAV.connect failed.', errorObject: e, classType: PageBackupPage).w();
    }
  }

  static Future<void> _webDavAction(DBActions action) async {
    try {
      if (_webDAV == null) throw Exception('WebDav 尚未被初始化');
      if (DateTime.now().millisecondsSinceEpoch - _lastTimeWebDAVSWork <= 8000) {
        LogService('太過頻繁的 WebDav 操作', classType: PageBackupPage).d();
        return;
      }
      _lastTimeWebDAVSWork = DateTime.now().millisecondsSinceEpoch;
      switch (action) {
        case DBActions.pushForce:
          await DriftServices.pushForce(_webDAV!.upload);
        case DBActions.push:
          await DriftServices.pushMerge(_webDAV!.download, _webDAV!.upload);
        case DBActions.pullForce:
          await DriftServices.pullForce(_webDAV!.download);
        case DBActions.pull:
          await DriftServices.pullMerge(_webDAV!.download);
        case DBActions.sync:
          await DriftServices.syncMerge(_webDAV!.download, _webDAV!.upload);
      }
      LogService('_webDavAction success.', classType: PageBackupPage).d();
    } catch (e) {
      LogService('_webDavAction failed.', errorObject: e, classType: PageBackupPage).w();
    }
  }

  static Future<void> _localAction(DBActions action, String filePath) async {
    try {
      Future<bool> upload(file) => DriftServices.uploadLocal(file, filePath);
      Future<File?> download() => DriftServices.downloadLocal(filePath);
      switch (action) {
        case DBActions.pushForce:
          await DriftServices.pushForce(upload);
        case DBActions.push:
          await DriftServices.pushMerge(download, upload);
        case DBActions.pullForce:
          await DriftServices.pullForce(download);
        case DBActions.pull:
          await DriftServices.pullMerge(download);
        case DBActions.sync:
          await DriftServices.syncMerge(download, upload);
      }
      LogService('_localAction success.', classType: PageBackupPage).d();
    } catch (e) {
      LogService('_localAction failed.', errorObject: e, classType: PageBackupPage).w();
    }
  }

  @override
  State<StatefulWidget> createState() => _PageBackupPageState();
}

class _PageBackupPageState extends State<PageBackupPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final List<String> _logs = [];
  late final StreamSubscription<LogService> _logSubscription;
  bool _isConnected = PageBackupPage._webDAV != null;
  String? _url;
  String? _user;
  String? _password;

  @override
  void initState() {
    super.initState();
    _logSubscription = LogService.stream.where((e) => e.level >= .debug).listen((data) {
      setState(() => _logs.insert(0, data.logString));
    });
    unawaited(_initLoad());
  }

  @override
  void dispose() {
    super.dispose();
    _logSubscription.cancel();
  }

  Future<void> _initLoad() async {
    _url = await SecurePrefs.webDAVUrl.read();
    _user = await SecurePrefs.webDAVUser.read();
    _password = await SecurePrefs.webDAVPassword.read();
    _formKey.currentState?.patchValue({
      'url': _url,
      'user': _user,
      'password': _password,
    });
  }

  Future<void> _pressSetNewWebDAV() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    _url = _formKey.currentState?.value['url'];
    _user = _formKey.currentState?.value['user'] ?? '';
    _password = _formKey.currentState?.value['password'] ?? '';
    await Future.value([
      SecurePrefs.webDAVUrl.write(_url!),
      SecurePrefs.webDAVUser.write(_user!),
      SecurePrefs.webDAVPassword.write(_password!),
    ]);
    await PageBackupPage.setWebDAV();
    setState(() {
      _isConnected = PageBackupPage._webDAV != null;
    });
  }

  Future<void> _pressSaveNew() async {
    final Directory? directory = await getDownloadsDirectory();
    final String? directoryPath = await FilePicker.platform.getDirectoryPath(initialDirectory:directory?.path);
    if (directoryPath == null) {
      await Utils.showToast('取消');
      return;
    }
    await PageBackupPage._localAction(.pushForce, p.join(directoryPath, 'pushForce_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}.sqlite'));
  }

  Future<void> _pressLocalOther(DBActions action) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: .custom,
      allowedExtensions: const ['sqlite'],
    );
    if (result == null) {
      await Utils.showToast('取消');
      return;
    }
    try {
      await PageBackupPage._localAction(action, result.files.single.path!);
    } catch (e) {
      Utils.showToast(e.toString());
    }
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
                      title: Text('另存新檔'),
                      onTap: _pressSaveNew,
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: Text('推送'),
                      onTap: () => _pressLocalOther(.push),
                    ),
                    if (context.readPrefs.get(.isAppDeveloperMode)) ListTile(
                      leading: const Icon(Icons.download),
                      title: Text('強拉取'),
                      onTap: () => _pressLocalOther(.pullForce),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text('拉取'),
                      onTap: () => _pressLocalOther(.pull),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text('同步'),
                      onTap: () => _pressLocalOther(.sync),
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
                      leading: _isConnected
                          ? Icon(Icons.cloud_outlined, color: Colors.green)
                          : Icon(Icons.cloud_off, color: Colors.grey),
                      title: Text(_isConnected ? '已連線' : '未連線'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload),
                      title: Text('強推送'),
                      onTap: _isConnected ? () => PageBackupPage._webDavAction(.pushForce) : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: Text('推送'),
                      onTap: _isConnected ? () => PageBackupPage._webDavAction(.push) : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: Text('強拉取'),
                      onTap: _isConnected ? () => PageBackupPage._webDavAction(.pullForce) : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text('拉取'),
                      onTap: _isConnected ? () => PageBackupPage._webDavAction(.pull) : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text('同步'),
                      onTap: _isConnected ? () => PageBackupPage._webDavAction(.sync) : null,
                    ),
                    ListTileSwitch(
                      text: '啟用定期同步',
                      initialValue: context.readPrefs.get(.isAutoWebDAVSync),
                      enabled: _isConnected,
                      onToggle: (value) async {
                        await context.readPrefs.update(.isAutoWebDAVSync, value, false);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              ExpandableCard(
                iconData: Icons.add_to_drive,
                text: 'WebDAV 參數',
                expandedChild:  FormBuilder(
                  key: _formKey,
                  child: Column(
                    children: [
                      ListTile(
                        minTileHeight: 0,
                        subtitle: Text('URL'),
                      ),
                      MyTextField(
                        name: 'url',
                        initialValue: _url,
                      ),
                      ListTile(
                        minTileHeight: 0,
                        subtitle: Text('User'),
                      ),
                      MyTextField(
                        name: 'user',
                        initialValue: _user,
                        required: false,
                      ),
                      ListTile(
                        minTileHeight: 0,
                        subtitle: Text('Password'),
                      ),
                      MyTextField(
                        name: 'password',
                        initialValue: _password,
                        type: .password,
                        required: false,
                      ),
                      ElevatedButton(
                        onPressed: _pressSetNewWebDAV,
                        child: Text('保存並嘗試連線'),
                      ),
                    ],
                  ),
                ),
              ),
              ExpandableCard(
                iconData: Icons.terminal,
                text: '即時日誌',
                expandedChild: Column(
                  children: [
                    for (final String log in _logs)
                      SelectableText(log),
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
