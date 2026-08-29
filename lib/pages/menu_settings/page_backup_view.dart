import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/widget/expandable_card.dart';
import 'package:receipt_fold/pages/widget/my_text_field.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';
import 'package:receipt_fold/services/drift_service.dart';
import 'package:receipt_fold/services/log_service.dart';
import 'package:receipt_fold/services/secure_prefs.dart';

enum DriftDispatcher {
  pushForce,
  push,
  pullForce,
  pull,
  sync;

  static Timer? _webDAVConnectSyncTimer;
  static int _lastTimeWebDAVAction = 0;
  static final ValueNotifier<bool> _singleActionLocked = ValueNotifier(false);
  static final ValueNotifier<WebDAVAdapter?> _webDAV = ValueNotifier(null);

  static Future<void> connectWebDAV({bool reConnect = false}) async {
    _webDAVConnectSyncTimer?.cancel();
    if (reConnect ||
        (_webDAV.value == null && PrefsEnum.isAutoWebDAVSync.get())) {
      _webDAV.value = null;
      final account = await _readWebDAVAccount();
      if (Utils.noEmptyStr(account.url) == null ||
          account.user == null ||
          account.password == null) {
        return;
      }
      try {
        _webDAV.value = await WebDAVAdapter.connect(
          url: account.url!,
          user: account.user!,
          password: account.password!,
          remoteDir: 'ReceiptFoldSync',
          remoteFileName: 'drift.sqlite.gz',
          decodeConverter: TransportAdapter.fileConverter(gzip.decoder),
          encodeConverter: TransportAdapter.fileConverter(gzip.encoder),
        );
      } catch (e) {
        LogService(
          'connectWebDAV failed.',
          errorObject: e,
          classType: DriftDispatcher,
        ).e();
      }
    }
    if (_webDAV.value != null && PrefsEnum.isAutoWebDAVSync.get()) {
      _webDAVConnectSyncTimer = Timer(
        const Duration(seconds: 4),
        sync.executeWebDAV,
      );
    }
  }

  Future<void> _execute(TransportAdapter adapter) => switch (this) {
    pushForce => DriftService.pushForce(adapter.upload).then((f) async {
      if (await f.exists()) await f.delete();
    }),
    push => DriftService.pushMerge(adapter.download, adapter.upload).then((
      f,
    ) async {
      if (await f.exists()) await f.delete();
    }),
    pullForce => DriftService.pullForce(adapter.download),
    pull => DriftService.pullMerge(adapter.download),
    sync => DriftService.syncMerge(adapter.download, adapter.upload),
  };

  Future<void> executeWebDAV() async {
    if (_singleActionLocked.value) {
      LogService('現在已有其他資料庫操作, 取消執行.', instance: this).d();
      return;
    } else if (UnitUtils.nowUnixTime - _lastTimeWebDAVAction < 2000) {
      LogService('太過頻繁的 WebDAV 操作, 取消執行.', instance: this).d();
      return;
    }
    _singleActionLocked.value = true;
    try {
      if (_webDAV.value == null) throw Exception('WebDAV cannot be null.');
      await _execute(_webDAV.value!);
      LogService('🟢 executeWebDAV finished.', instance: this).d();
    } catch (e) {
      LogService('executeWebDAV failed.', errorObject: e, instance: this).e();
    } finally {
      _lastTimeWebDAVAction = UnitUtils.nowUnixTime;
      _singleActionLocked.value = false;
    }
  }

  Future<void> executeDevice(String filePath) async {
    if (_singleActionLocked.value) {
      LogService('現在已有其他資料庫操作, 取消執行.', instance: this).d();
      return;
    }
    _singleActionLocked.value = true;
    try {
      await _execute(DeviceAdapter(filePath));
      LogService('🟢 executeDevice finished.', instance: this).d();
    } catch (e) {
      LogService('executeDevice failed.', errorObject: e, instance: this).e();
    } finally {
      _singleActionLocked.value = false;
    }
  }
}

Future<({String? url, String? user, String? password})>
_readWebDAVAccount() async {
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
  return (url: url, user: user, password: password);
}

class PageBackupView extends StatefulWidget {
  const PageBackupView({super.key});

  @override
  State<StatefulWidget> createState() => _PageBackupViewState();
}

class _PageBackupViewState extends State<PageBackupView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _logScrollController = ScrollController();
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final _logs = <String>[];
  late final StreamSubscription<LogService> _logSubscription;

  @override
  void initState() {
    super.initState();
    _logSubscription = LogService.stream
        .where((e) => e.level >= Level.debug)
        .listen((data) {
          setState(() => _logs.insert(0, data.logString));
        });
  }

  @override
  void dispose() {
    super.dispose();
    _logSubscription.cancel();
    _scrollController.dispose();
    _logScrollController.dispose();
  }

  Future<void> _pressDevicePushFile() async {
    final Directory? directory = await getDownloadsDirectory();
    final String? directoryPath = await FilePicker.getDirectoryPath(
      initialDirectory: directory?.path,
    );
    if (directoryPath == null) {
      Utils.showToast(DictKey.commonUiCancel.s);
      return;
    }
    await DriftDispatcher.pushForce.executeDevice(
      p.join(directoryPath, 'ReceiptFold_${UnitUtils.unixRadix36}.sqlite'),
    );
  }

  Future<void> _pressDeviceAction(DriftDispatcher action) async {
    final PlatformFile? result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['sqlite'],
    );
    if (result == null) {
      Utils.showToast(DictKey.commonUiCancel.s);
      return;
    }
    await action.executeDevice(result.path!);
  }

  Future<void> _pressSetWebDAV() async {
    final account = await _readWebDAVAccount();
    await OverlayShow.bottomSheet(
      context: context,
      noCancelButton: true,
      title: ListTile(
        title: Text(DictKey.backupConnectionSetting.s),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        trailing: ElevatedButton(
          child: Text(DictKey.backupSaveAndConnect.s),
          onPressed: () async {
            if (_formKey.currentState?.saveAndValidate() != true) return;
            Navigator.pop(context);
            await SecurePrefs.webDAVAccount.write(
              jsonEncode({
                'url': _formKey.currentState!.value['url'] ?? '',
                'user': _formKey.currentState!.value['user'] ?? '',
                'password': _formKey.currentState!.value['password'] ?? '',
              }),
            );
            await DriftDispatcher.connectWebDAV(reConnect: true);
          },
        ),
      ),
      content: FormBuilder(
        key: _formKey,
        child: Column(
          spacing: 16,
          children: [
            MyTextField(
              labelText: DictKey.backupUrlLabel.s,
              name: 'url',
              initialValue: account.url,
              required: false,
            ),
            MyTextField(
              labelText: DictKey.backupUserLabel.s,
              name: 'user',
              initialValue: account.user,
              required: false,
            ),
            MyTextField(
              labelText: DictKey.backupPasswordLabel.s,
              name: 'password',
              initialValue: account.password,
              type: FieldType.password,
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
      appBar: AppBar(title: Text(DictKey.settingDataBackup.s)),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            children: [
              ValueListenableBuilder(
                valueListenable: DriftDispatcher._singleActionLocked,
                builder: (context, value, child) => value
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink(),
              ),
              ExpandableCard(
                iconData: Icons.devices,
                text: DictKey.backupDevice.s,
                expandedChild: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload),
                      title: Text(DictKey.backupDevicePushFile.s),
                      onTap: _pressDevicePushFile,
                    ),
                    ListTile(
                      leading: const Icon(Icons.upload_outlined),
                      title: Text(DictKey.backupPush.s),
                      onTap: () => _pressDeviceAction(.push),
                    ),
                    if (context.readPrefs.get(.isAppDeveloperMode))
                      ListTile(
                        leading: const Icon(Icons.download),
                        title: Text(DictKey.backupPullForce.s),
                        onTap: () => _pressDeviceAction(.pullForce),
                      ),
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: Text(DictKey.backupPull.s),
                      onTap: () => _pressDeviceAction(.pull),
                    ),
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text(DictKey.backupSync.s),
                      onTap: () => _pressDeviceAction(.sync),
                    ),
                  ],
                ),
              ),
              ExpandableCard(
                iconData: Icons.cloud_sync,
                text: DictKey.backupWebDAV.s,
                expandedChild: ValueListenableBuilder(
                  valueListenable: DriftDispatcher._webDAV,
                  builder: (context, webDAV, child) {
                    final bool isConnected = webDAV != null;
                    return Column(
                      children: [
                        ListTile(
                          leading: isConnected
                              ? const Icon(
                                  Icons.cloud_outlined,
                                  color: Colors.green,
                                )
                              : const Icon(Icons.cloud_off, color: Colors.grey),
                          title: Text(DictKey.backupConnectionSetting.s),
                          onTap: _pressSetWebDAV,
                        ),
                        if (context.readPrefs.get(.isAppDeveloperMode))
                          ListTile(
                            leading: const Icon(Icons.upload),
                            title: Text(DictKey.backupPushForce.s),
                            enabled: isConnected,
                            onTap: DriftDispatcher.pushForce.executeWebDAV,
                          ),
                        ListTile(
                          leading: const Icon(Icons.upload_outlined),
                          title: Text(DictKey.backupPush.s),
                          enabled: isConnected,
                          onTap: DriftDispatcher.push.executeWebDAV,
                        ),
                        if (context.readPrefs.get(.isAppDeveloperMode))
                          ListTile(
                            leading: const Icon(Icons.download),
                            title: Text(DictKey.backupPullForce.s),
                            enabled: isConnected,
                            onTap: DriftDispatcher.pullForce.executeWebDAV,
                          ),
                        ListTile(
                          leading: const Icon(Icons.download_outlined),
                          title: Text(DictKey.backupPull.s),
                          enabled: isConnected,
                          onTap: DriftDispatcher.pull.executeWebDAV,
                        ),
                        ListTile(
                          leading: const Icon(Icons.sync),
                          title: Text(DictKey.backupSync.s),
                          enabled: isConnected,
                          onTap: DriftDispatcher.sync.executeWebDAV,
                        ),
                        ListTileSwitch(
                          iconData: Icons.motion_photos_auto,
                          text: DictKey.backupAutoSync.s,
                          initialValue: context.readPrefs.get(
                            .isAutoWebDAVSync,
                          ),
                          onToggle: (value) async {
                            await context.readPrefs.update(
                              .isAutoWebDAVSync,
                              value,
                              false,
                            );
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
                text: DictKey.commonUiRealTimeLog.s,
                expandedChild: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    maxHeight: 400.0,
                  ),
                  child: Scrollbar(
                    controller: _logScrollController,
                    child: SingleChildScrollView(
                      controller: _logScrollController,
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
