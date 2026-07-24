import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:path/path.dart' as p;
import 'package:receipt_fold/modules/log_service.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

typedef Download = Future<File?> Function();
typedef Upload = Future<File> Function(File);

abstract final class DriftServices {
  static late final MyDriftDatabase appDb;

  static MyDriftDatabase _openFileDb(File file) => MyDriftDatabase(
    NativeDatabase(
      file,
      setup: (db) => db.execute('PRAGMA journal_mode = DELETE;'),
    ),
  );

  static Future<File> pushForce(Upload upload) async {
    LogService('pushForce...', classType: DriftServices).d();
    final Directory tempDir = await getTemporaryDirectory();
    final File appDbCopyFile = File(p.join(tempDir.path, 'pushForce_${UnitUtils.unixRadix36}.sqlite'));
    await appDb.selfTidy();
    try {
      await appDb.customStatement("VACUUM INTO '${appDbCopyFile.path}'");
      if (!await appDbCopyFile.exists()) throw Exception('Copy AppDb to ${appDbCopyFile.path} failed.');
      return await upload(appDbCopyFile);
    } catch (_) {
      if (await appDbCopyFile.exists()) await appDbCopyFile.delete();
      rethrow;
    }
  }

  static Future<File> pushMerge(Download download, Upload upload) async {
    LogService('pushMerge...', classType: DriftServices).d();
    final File? downloadFile = await download();
    if (downloadFile == null || !await downloadFile.exists()) return await pushForce(upload);
    await appDb.selfTidy();
    try {
      final MyDriftDatabase downloadDb = _openFileDb(downloadFile);
      await downloadDb.mergeFrom(appDb).whenComplete(downloadDb.close);
      return await upload(downloadFile);
    } catch (_) {
      if (await downloadFile.exists()) await downloadFile.delete();
      rethrow;
    }
  }

  static Future<void> pullForce(Download download) async {
    LogService('pullForce...', classType: DriftServices).d();
    final File? downloadFile = await download();
    if (downloadFile == null || !await downloadFile.exists()) {
      LogService('downloadFile(${downloadFile?.path}) does not exists.', classType: DriftServices).d();
      return;
    }
    try {
      await appDb.transaction(() async {
        await appDb.batch((batch) {
          for (final table in appDb.allTables) {
            batch.deleteAll(table);
          }
        });
        await pullMerge(() => SynchronousFuture(downloadFile));
      });
    } finally {
      if (await downloadFile.exists()) await downloadFile.delete();
    }
  }

  static Future<void> pullMerge(Download download) async {
    LogService('pullMerge...', classType: DriftServices).d();
    final File? downloadFile = await download();
    if (downloadFile == null || !await downloadFile.exists()) {
      LogService('downloadFile(${downloadFile?.path}) does not exists.', classType: DriftServices).d();
      return;
    }
    try {
      final MyDriftDatabase downloadDb = _openFileDb(downloadFile);
      await appDb.mergeFrom(downloadDb).whenComplete(downloadDb.close);
    } finally {
      if (await downloadFile.exists()) await downloadFile.delete();
    }
  }

  static Future<void> syncMerge(Download download, Upload upload) async {
    LogService('syncMerge...', classType: DriftServices).d();
    final File downloadFile = await pushMerge(download, upload);
    await pullMerge(() => SynchronousFuture(downloadFile));
  }
}

/// 用於 File I/O 交換層, 請保持 [download] is [Download], [upload] is [Upload] 的型別.
abstract class TransportAdapter {
  const TransportAdapter();

  /// 產生的 [File] 應要能夠被刪除的暫存檔, 直接給原檔路徑給 [DriftServices] 會被刪.
  ///
  /// 請在錯誤時 throw 中斷, 僅當對應位置無檔案時為 null 表示.
  Future<File?> download();

  /// 請確定執行過程如果不穩定斷連能夠不覆蓋到正常還沒被取代掉的目的地.
  ///
  /// 傳入的 [file] 實踐時不要手動刪除, 上傳成功回傳自己的參數 [file], 失敗 throw.
  Future<File> upload(File file);
}

class DeviceAdapter extends TransportAdapter {
  final String _filePath;

  const DeviceAdapter(this._filePath);

  @override
  Future<File?> download() async {
    LogService('download...', instance: this).d();
    final File sourceFile = File(_filePath);
    if (!await sourceFile.exists()) return null;
    final Directory tempDir = await getTemporaryDirectory();
    return sourceFile.copy(p.join(tempDir.path, 'device_download_${UnitUtils.unixRadix36}.tmp'));
  }

  @override
  Future<File> upload(File file) async {
    LogService('upload...', instance: this).d();
    final File targetFile = File(_filePath);
    final File tempFile = File('$_filePath.tmp');
    try {
      if (!await targetFile.parent.exists()) await targetFile.parent.create(recursive: true);
      await file.copy(tempFile.path);
      await tempFile.rename(targetFile.path);
      return file;
    } catch (_) {
      if (await tempFile.exists()) await tempFile.delete();
      rethrow;
    }
  }
}

class WebDAVAdapter extends TransportAdapter {
  final webdav.Client client;
  final String remoteDir;
  final String remoteFileName;
  late final String remotePath = p.posix.join(remoteDir, remoteFileName);

  WebDAVAdapter._(this.client, this.remoteDir, this.remoteFileName);

  static Future<WebDAVAdapter> connect(String url, String user, String password, {
    String remoteDir = 'ReceiptFoldSync',
    String remoteFileName = 'drift.sqlite.gz',
  }) async {
    final WebDAVAdapter self = WebDAVAdapter._(webdav.newClient(url, user: user, password: password), remoteDir, remoteFileName);
    self.client.setHeaders({'content-type': 'application/octet-stream'});
    await self.client.ping();
    await self.client.mkdirAll(remoteDir);
    return self;
  }

  /// [converter] 可以傳入 [gzip.decoder] 來壓縮, 或是傳入 [gzip.encoder] 解壓縮.
  static Future<File> convertFile(File sourceFile, Converter<List<int>, List<int>> converter) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File(p.join(tempDir.path, 'WebDAV_convertFile_${UnitUtils.unixRadix36}.tmp'));
    final Stream<List<int>> input = sourceFile.openRead();
    final IOSink output = file.openWrite();
    bool success = false;
    try {
      await input.transform(converter).pipe(output);
      success = true;
      return file;
    } finally {
      await output.close();
      if (!success && await file.exists()) await file.delete();
    }
  }

  @override
  Future<File?> download([Future<File> Function(File)? fileTransform]) async {
    LogService('download...', instance: this).d();
    late final webdav.File remoteFile;
    try {
      final remoteFiles = await client.readDir(remoteDir);
      remoteFile = remoteFiles.firstWhere((f) => f.name == remoteFileName);
    } catch (e) {
      LogService('$remotePath not found.', errorObject: e, instance: this).d();
      return null;
    }
    if (remoteFile.isDir == true) throw Exception('$this.download: ${remoteFile.path} cannot be directory.');
    final Directory tempDir = await getTemporaryDirectory();
    final File downloadFile = File(p.join(tempDir.path, 'WebDAV_download_${UnitUtils.unixRadix36}.tmp'));
    try {
      await client.read2File(remoteFile.path!, downloadFile.path);
      return await (fileTransform ?? (file) => convertFile(file, gzip.decoder))(downloadFile);
    } finally {
      if (await downloadFile.exists()) await downloadFile.delete();
    }
  }

  @override
  Future<File> upload(File file, [Future<File> Function(File)? fileTransform]) async {
    LogService('upload...', instance: this).d();
    final String remoteCachePath = '$remotePath.cache';
    // try {
    //   await client.remove(remoteCachePath);
    // } catch (e) {
    //   LogService('client.remove($remoteCachePath)', errorObject: e, instance: this).t();
    // }
    final File convertedFile = await (fileTransform ?? (file) => convertFile(file, gzip.encoder))(file);
    try {
      await client.writeFromFile(convertedFile.path, remoteCachePath);
      // try {
      //   await client.remove(remotePath);
      // } catch (e) {
      //   LogService('client.remove($remotePath)', errorObject: e, instance: this).t();
      // }
      await client.rename(remoteCachePath, remotePath, true);
    } catch (_) {
      try {
        await client.remove(remoteCachePath);
      } catch (e) {
        LogService('client.remove($remoteCachePath)', errorObject: e, instance: this).t();
      }
      rethrow;
    } finally {
      if (await convertedFile.exists()) await convertedFile.delete();
    }
    return file;
  }
}
