import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/modules/secure_prefs.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
import 'package:receipt_fold/pages/widget/expandable_card.dart';
import 'package:receipt_fold/pages/widget/my_text_field.dart';
import 'package:path/path.dart' as p;
import 'package:receipt_fold/pages/widget/overlay_show.dart';

enum _DriftAction {
  pushForce,
  push,
  pullForce,
  pull,
  sync,
}

Future<({String? url, String? user, String? password})> _readWebDAVAccount() async {
  String? url;
  String? user;
  String? password;
  final String? jsonString = await SecurePrefs.webDAVAccount.read();
  try {
    if (jsonString != null) {
      final Map map = jsonDecode(jsonString);
      url = map['url'];
      user = map['user'];
      password = map['password'];
    }
  } catch (e) {
    debugPrint('_readWebDAVAccount: $e');
  }
  return (
  url: url,
  user: user,
  password: password
  );
}

class PageBackupPage extends StatefulWidget {
  const PageBackupPage({super.key});

  static Timer? _webDAVConnectSyncTimer;
  static int _lastTimeWebDAVAction = 0;
  static final ValueNotifier<bool> _singleActionLocked = ValueNotifier(false);
  static final ValueNotifier<WebDAV?> _webDAV = ValueNotifier(null);

  static Future<void> connectWebDAV({bool reConnect = false}) async {
    _webDAVConnectSyncTimer?.cancel();
    if (reConnect || (_webDAV.value == null && PrefsEnum.isAutoWebDAVSync.get())) {
      _webDAV.value = null;
      final account = await _readWebDAVAccount();
      if (account.url == null || account.user == null || account.password == null || account.url!.isEmpty) return;
      try {
        _webDAV.value = await WebDAV.connect(account.url!, account.user!, account.password!);
      } catch (e) {
        LogService('connectWebDAV failed.', errorObject: e, classType: PageBackupPage).e();
      }
    }
    if (_webDAV.value != null && PrefsEnum.isAutoWebDAVSync.get()) {
      _webDAVConnectSyncTimer = Timer(const Duration(seconds: 3), () => _webDAVAction(.sync));
    }
  }

  static Future<void> _webDAVAction(_DriftAction action) async {
    if (_singleActionLocked.value) {
      LogService('現在已有其他資料庫操作, 取消執行.', classType: PageBackupPage).d();
      return;
    } else if (UnitUtils.nowUnixTime - _lastTimeWebDAVAction <= 2000) {
      LogService('太過頻繁的 WebDAV 操作, 取消執行.', classType: PageBackupPage).d();
      return;
    }
    _singleActionLocked.value = true;
    try {
      if (_webDAV.value == null) throw Exception('WebDAV 尚未被初始化!');
      _lastTimeWebDAVAction = UnitUtils.nowUnixTime;
      final WebDAV webDAV = _webDAV.value!;
      await switch (action) {
        .pushForce => DriftServices.pushForce(webDAV.upload),
        .push => DriftServices.pushMerge(webDAV.download, webDAV.upload),
        .pullForce => DriftServices.pullForce(webDAV.download),
        .pull => DriftServices.pullMerge(webDAV.download),
        .sync => DriftServices.syncMerge(webDAV.download, webDAV.upload),
      };
      LogService('_webDAVAction finished.', classType: PageBackupPage).d();
    } catch (e) {
      LogService('_webDAVAction failed.', errorObject: e, classType: PageBackupPage).e();
    } finally {
      _singleActionLocked.value = false;
    }
  }

  static Future<void> _localAction(_DriftAction action, String filePath) async {
    if (_singleActionLocked.value) {
      LogService('現在已有其他資料庫操作, 取消執行.', classType: PageBackupPage).d();
      return;
    }
    _singleActionLocked.value = true;
    try {
      Future<bool> upload(file) => DriftServices.uploadLocal(file, filePath);
      Future<File?> download() => DriftServices.downloadLocal(filePath);
      await switch (action) {
        .pushForce => DriftServices.pushForce(upload),
        .push => DriftServices.pushMerge(download, upload),
        .pullForce => DriftServices.pullForce(download),
        .pull => DriftServices.pullMerge(download),
        .sync => DriftServices.syncMerge(download, upload),
      };
      LogService('_localAction finished.', classType: PageBackupPage).d();
    } catch (e) {
      LogService('_localAction failed.', errorObject: e, classType: PageBackupPage).e();
    } finally {
      _singleActionLocked.value = false;
    }
  }

  @override
  State<StatefulWidget> createState() => _PageBackupPageState();
}

class _PageBackupPageState extends State<PageBackupPage> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final List<String> _logs = [];
  late final StreamSubscription<LogService> _logSubscription;

  @override
  void initState() {
    super.initState();
    _logSubscription = LogService.stream.where((e) => e.level >= .debug).listen((data) {
      setState(() => _logs.insert(0, data.logString));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _logSubscription.cancel();
  }

  Future<void> _pressLocalCopy() async {
    final Directory? directory = await getDownloadsDirectory();
    final String? directoryPath = await FilePicker.platform.getDirectoryPath(initialDirectory:directory?.path);
    if (directoryPath == null) {
      await Utils.showToast('取消');
      return;
    }
    await PageBackupPage._localAction(.pushForce, p.join(directoryPath, 'ReceiptFold_${UnitUtils.unixRadix36}.sqlite'));
  }

  Future<void> _pressLocalAction(_DriftAction action) async {
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

  Future<void> _pressSetWebDAV() async {
    final account = await _readWebDAVAccount();
    await OverlayShow.bottomSheet(
      context: context,
      noCancelButton: true,
      title: ListTile(
        title: Text('連線設定'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        trailing: ElevatedButton(
          child: Text('保存並嘗試連線'),
          onPressed: () async {
            if (_formKey.currentState?.saveAndValidate() != true) return;
            Navigator.pop(context);
            await SecurePrefs.webDAVAccount.write(jsonEncode({
              'url': _formKey.currentState?.value['url'] ?? '',
              'user': _formKey.currentState?.value['user'] ?? '',
              'password': _formKey.currentState?.value['password'] ?? '',
            }));
            await PageBackupPage.connectWebDAV(reConnect: true);
          },
        ),
      ),
      content: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            ListTile(
              minTileHeight: 0,
              subtitle: Text('URL'),
            ),
            MyTextField(
              name: 'url',
              initialValue: account.url,
              required: false,
            ),
            ListTile(
              minTileHeight: 0,
              subtitle: Text('User'),
            ),
            MyTextField(
              name: 'user',
              initialValue: account.user,
              required: false,
            ),
            ListTile(
              minTileHeight: 0,
              subtitle: Text('Password'),
            ),
            MyTextField(
              name: 'password',
              initialValue: account.password,
              type: .password,
              required: false,
            ),
          ],
        ),
      ),
    );
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
              ValueListenableBuilder(
                valueListenable: PageBackupPage._singleActionLocked,
                builder: (context, value, child) => value ? const LinearProgressIndicator() : const SizedBox.shrink(),
              ),
              ExpandableCard(
                iconData: Icons.devices,
                text: '本地動作',
                expandedChild: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload),
                      title: Text('另存新檔'),
                      onTap: _pressLocalCopy,
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: Text('推送'),
                      onTap: () => _pressLocalAction(.push),
                    ),
                    if (context.readPrefs.get(.isAppDeveloperMode)) ListTile(
                      leading: const Icon(Icons.download),
                      title: Text('強拉取'),
                      onTap: () => _pressLocalAction(.pullForce),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text('拉取'),
                      onTap: () => _pressLocalAction(.pull),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text('同步'),
                      onTap: () => _pressLocalAction(.sync),
                    ),
                  ],
                ),
              ),
              ExpandableCard(
                iconData: Icons.cloud_sync,
                text: 'WebDAV',
                expandedChild: ValueListenableBuilder(
                  valueListenable: PageBackupPage._webDAV,
                  builder: (context, webDAV, child) {
                    final bool isConnected = webDAV != null;
                    return Column(
                      children: [
                        ListTile(
                          leading: isConnected
                              ? const Icon(Icons.cloud_outlined, color: Colors.green)
                              : const Icon(Icons.cloud_off, color: Colors.grey),
                          title: Text('連線設定'),
                          onTap: _pressSetWebDAV,
                        ),
                        if (context.readPrefs.get(.isAppDeveloperMode)) ListTile(
                          leading: const Icon(Icons.upload),
                          title: Text('強推送'),
                          enabled: isConnected,
                          onTap: () => PageBackupPage._webDAVAction(.pushForce),
                        ),
                        ListTile(
                          leading: const Icon(Icons.upload_outlined),
                          title: Text('推送'),
                          enabled: isConnected,
                          onTap: () => PageBackupPage._webDAVAction(.push),
                        ),
                        if (context.readPrefs.get(.isAppDeveloperMode)) ListTile(
                          leading: const Icon(Icons.download),
                          title: Text('強拉取'),
                          enabled: isConnected,
                          onTap: () => PageBackupPage._webDAVAction(.pullForce),
                        ),
                        ListTile(
                          leading: const Icon(Icons.download_outlined),
                          title: Text('拉取'),
                          enabled: isConnected,
                          onTap: () => PageBackupPage._webDAVAction(.pull),
                        ),
                        ListTile(
                          leading: const Icon(Icons.sync),
                          title: Text('同步'),
                          enabled: isConnected,
                          onTap: () => PageBackupPage._webDAVAction(.sync),
                        ),
                        ListTileSwitch(
                          iconData: Icons.motion_photos_auto,
                          text: '啟用定期同步',
                          initialValue: context.readPrefs.get(.isAutoWebDAVSync),
                          onToggle: (value) async {
                            await context.readPrefs.update(.isAutoWebDAVSync, value, false);
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              ExpandableCard(
                iconData: Icons.terminal,
                text: '即時日誌',
                expandedChild: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    maxHeight: 400.0,
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: SelectableText(_logs.join('\n')),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
