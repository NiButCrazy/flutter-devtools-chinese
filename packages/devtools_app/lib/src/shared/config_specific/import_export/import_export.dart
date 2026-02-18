// Copyright 2020 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:convert';

import 'package:devtools_app_shared/service.dart';
import 'package:intl/intl.dart';

import '../../framework/screen.dart';
import '../../globals.dart';
import '../../primitives/encoding.dart';
import '../../primitives/utils.dart';
import '../../utils/utils.dart';
import '_export_desktop.dart' if (dart.library.js_interop) '_export_web.dart';

const nonDevToolsFileMessage =
    '导入的文件不是 Dart DevTools 文件，目前，DevTools 仅支持导入源自 DevTools 导出的文件';

String attemptingToImportMessage(String devToolsScreen) {
  return '正在尝试为 ID - "$devToolsScreen" 的界面导入文件';
}

String successfulExportMessage(String exportedFile) {
  return '已成功将 $exportedFile 导出到 ~/Downloads 目录';
}

enum DevToolsExportKeys {
  devToolsSnapshot,
  devToolsVersion,
  connectedApp,
  activeScreenId,
}

class ImportController {
  ImportController(this._pushSnapshotScreenForImport);

  static const repeatImportTimeBufferMs = 500;

  final void Function(String screenId) _pushSnapshotScreenForImport;

  DateTime? previousImportTime;

  // TODO(kenz): improve error handling here or in snapshot_screen.dart.
  void importData(DevToolsJsonFile jsonFile, {String? expectedScreenId}) {
    // Do not allow two different imports within 500 ms of each other. This is a
    // workaround for the fact that we get two drop events for the same file.
    final now = DateTime.now();
    if (previousImportTime != null &&
        (now.millisecondsSinceEpoch -
                    previousImportTime!.millisecondsSinceEpoch)
                .abs() <
            repeatImportTimeBufferMs) {
      return;
    }
    previousImportTime = now;

    final json = jsonFile.data;
    final isDevToolsSnapshot =
        json is Map<String, Object?> &&
        json[DevToolsExportKeys.devToolsSnapshot.name] == true;
    if (!isDevToolsSnapshot) {
      notificationService.push(nonDevToolsFileMessage);
      return;
    }

    final devToolsOfflineData = _DevToolsOfflineData(json);
    // TODO(kenz): support imports for more than one screen at a time.
    final activeScreenId = devToolsOfflineData.activeScreenId;
    if (expectedScreenId != null && activeScreenId != expectedScreenId) {
      notificationService.push(
        '预期导入的是界面 \'$expectedScreenId\' 的数据文件，但实际收到的是界面 \'$activeScreenId\' 的文件，请打开界面 \'$expectedScreenId\' 的数据文件',
      );
      return;
    }

    if (activeScreenId == ScreenMetaData.performance.id) {
      if (devToolsOfflineData.json.containsKey('traceEvents')) {
        notificationService.push(
          '看起来您正在尝试加载由旧版本 DevTools 保存的数据，该数据使用的旧格式已不再受支持。要在 DevTools 中加载此文件，您需要将 Flutter 版本降级到 < 3.22。',
        );
        return;
      }
    }

    final connectedApp = OfflineConnectedApp.parse(
      devToolsOfflineData.connectedApp,
    );
    offlineDataController
      ..startShowingOfflineData(offlineApp: connectedApp)
      ..offlineDataJson = devToolsOfflineData.json;
    notificationService.push(attemptingToImportMessage(activeScreenId));
    _pushSnapshotScreenForImport(activeScreenId);
  }
}

extension type _DevToolsOfflineData(Map<String, Object?> json) {
  Map<String, Object?> get connectedApp {
    final connectedApp = json[DevToolsExportKeys.connectedApp.name] as Map?;
    return connectedApp == null ? {} : connectedApp.cast<String, Object?>();
  }

  String get activeScreenId =>
      json[DevToolsExportKeys.activeScreenId.name] as String;
}

enum ExportFileType {
  json,
  csv,
  yaml,
  data,
  har;

  @override
  String toString() => name;
}

abstract class ExportController {
  factory ExportController() {
    return createExportController();
  }

  const ExportController.impl();

  static String generateFileName({
    String prefix = 'dart_devtools',
    String postfix = '',
    required ExportFileType type,
    DateTime? time,
  }) {
    time ??= DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd_HH:mm:ss.SSS').format(time);
    return '${prefix}_$timestamp$postfix.$type';
  }

  /// Downloads a file with [content]
  /// and pushes notification about success if [notify] is true.
  String downloadFile<T>(
    T content, {
    String? fileName,
    ExportFileType type = ExportFileType.json,
    bool notify = true,
  }) {
    fileName ??= ExportController.generateFileName(type: type);
    saveFile<T>(content: content, fileName: fileName);
    notificationService.push(successfulExportMessage(fileName));
    return fileName;
  }

  /// Saves [content] to the [fileName].
  void saveFile<T>({required T content, required String fileName});

  Map<String, Object?> generateDataForExport({
    required Map<String, Object?> offlineScreenData,
    ConnectedApp? connectedApp,
  }) {
    final contents = {
      DevToolsExportKeys.devToolsSnapshot.name: true,
      DevToolsExportKeys.devToolsVersion.name: devToolsVersion,
      DevToolsExportKeys.connectedApp.name:
          connectedApp?.toJson() ??
          serviceConnection.serviceManager.connectedApp!.toJson(),
      ...offlineScreenData,
    };
    // TODO(kenz): ensure that performance page exports can be loaded properly
    // into the Perfetto UI (ui.perfetto.dev).
    return contents;
  }

  String encode(Map<String, Object?> offlineScreenData) {
    final data = generateDataForExport(offlineScreenData: offlineScreenData);
    return jsonEncode(data, toEncodable: toEncodable);
  }
}
