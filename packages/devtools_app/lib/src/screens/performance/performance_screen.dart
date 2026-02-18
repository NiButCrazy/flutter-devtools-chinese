// Copyright 2019 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../shared/analytics/analytics.dart' as ga;
import '../../shared/analytics/constants.dart' as gac;
import '../../shared/config_specific/import_export/import_export.dart';
import '../../shared/framework/screen.dart';
import '../../shared/globals.dart';
import '../../shared/managers/banner_messages.dart';
import '../../shared/ui/common_widgets.dart';
import '../../shared/ui/file_import.dart';
import '../../shared/utils/utils.dart';
import 'panes/controls/performance_controls.dart';
import 'panes/flutter_frames/flutter_frames_chart.dart';
import 'performance_controller.dart';
import 'tabbed_performance_view.dart';

// TODO(kenz): handle small screen widths better by using Wrap instead of Row
// where applicable.

class PerformanceScreen extends Screen {
  PerformanceScreen() : super.fromMetaData(ScreenMetaData.performance);

  static final id = ScreenMetaData.performance.id;

  @override
  String get docPageId => id;

  @override
  Widget buildScreenBody(BuildContext context) {
    if (serviceConnection.serviceManager.connectedApp?.isDartWebAppNow ??
        false) {
      return const WebPerformanceScreenBody();
    }
    return const PerformanceScreenBody();
  }

  @override
  Widget buildDisconnectedScreenBody(BuildContext context) {
    return const DisconnectedPerformanceScreenBody();
  }
}

class PerformanceScreenBody extends StatefulWidget {
  const PerformanceScreenBody({super.key});

  @override
  PerformanceScreenBodyState createState() => PerformanceScreenBodyState();
}

class PerformanceScreenBodyState extends State<PerformanceScreenBody>
    with AutoDisposeMixin {
  late PerformanceController controller;

  @override
  void initState() {
    super.initState();
    ga.screen(PerformanceScreen.id);
    controller = screenControllers.lookup<PerformanceController>();
    addAutoDisposeListener(offlineDataController.showingOfflineData);
    addAutoDisposeListener(controller.loadingOfflineData);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    maybePushDebugModePerformanceMessage(PerformanceScreen.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.initialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            controller.loadingOfflineData.value) {
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const CenteredCircularProgressIndicator(),
          );
        }

        final showingOfflineData =
            offlineDataController.showingOfflineData.value;
        final isOfflineFlutterApp =
            showingOfflineData &&
            controller.offlinePerformanceData != null &&
            controller.offlinePerformanceData!.frames.isNotEmpty;
        return Column(
          children: [
            PerformanceControls(
              controller: controller,
              onClear: () => setState(() {}),
            ),
            const SizedBox(height: intermediateSpacing),
            if (isOfflineFlutterApp ||
                (!showingOfflineData &&
                    serviceConnection
                        .serviceManager
                        .connectedApp!
                        .isFlutterAppNow!))
              FlutterFramesChart(
                controller.flutterFramesController,
                showingOfflineData: showingOfflineData,
                impellerEnabled: controller.impellerEnabled,
              ),
            const Expanded(child: TabbedPerformanceView()),
          ],
        );
      },
    );
  }
}

class WebPerformanceScreenBody extends StatelessWidget {
  const WebPerformanceScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isFlutterWebApp =
        serviceConnection.serviceManager.connectedApp?.isFlutterWebAppNow ??
        false;
    return Markdown(
      data: isFlutterWebApp ? flutterWebInstructionsMd : dartWebInstructionsMd,
      onTapLink: (_, url, _) {
        if (url != null) {
          unawaited(launchUrlWithErrorHandling(url));
        }
      },
    );
  }
}

class DisconnectedPerformanceScreenBody extends StatelessWidget {
  const DisconnectedPerformanceScreenBody({super.key});

  static const importInstructions =
      '打开之前从 DevTools 保存的性能分析数据文件';

  @override
  Widget build(BuildContext context) {
    return FileImportContainer(
      instructions: importInstructions,
      actionText: '加载数据',
      gaScreen: gac.performance,
      gaSelectionImport: gac.PerformanceEvents.openDataFile.name,
      gaSelectionAction: gac.PerformanceEvents.loadDataFromFile.name,
      onAction: (jsonFile) {
        Provider.of<ImportController>(
          context,
          listen: false,
        ).importData(jsonFile, expectedScreenId: PerformanceScreen.id);
      },
    );
  }
}

const timelineLink =
    'https://api.flutter.dev/flutter/dart-developer/Timeline-class.html';
const timelineTaskLink =
    'https://api.flutter.dev/flutter/dart-developer/TimelineTask-class.html';
const debugBuildsLink =
    'https://api.flutter.dev/flutter/widgets/debugProfileBuildsEnabled.html';
const debugUserBuildsLink =
    'https://api.flutter.dev/flutter/widgets/debugProfileBuildsEnabledUserWidgets.html';
const debugLayoutsLink =
    'https://api.flutter.dev/flutter/rendering/debugProfileLayoutsEnabled.html';
const debugPaintsLink =
    'https://api.flutter.dev/flutter/rendering/debugProfilePaintsEnabled.html';
const profileModeLink = 'https://flutter.dev/to/profile-mode';
const performancePanelLink =
    'https://developer.chrome.com/docs/devtools/performance';

const flutterWebInstructionsMd =
    '''
## 如何使用 Chrome DevTools 进行性能分析

Flutter 框架在构建帧、绘制场景，以及跟踪垃圾回收等活动时，会发出时间线事件。
这些事件会在 Chrome DevTools 的 Performance 面板中暴露用于调试。

你也可以使用 `dart:developer` 中的
[Timeline]($timelineLink) 和 [TimelineTask]($timelineTaskLink) API 来发出你自己的时间线事件，以便进行进一步的性能分析。

### 可选标志以增强跟踪

- [debugProfileBuildsEnabled]($debugBuildsLink)：为每个构建的 Widget 添加时间线事件
- [debugProfileBuildsEnabledUserWidgets]($debugUserBuildsLink)：为每个用户创建的 Widget 添加时间线事件
- [debugProfileLayoutsEnabled]($debugLayoutsLink)：为每个 RenderObject 的布局添加时间线事件
- [debugProfilePaintsEnabled]($debugPaintsLink)：为每个 RenderObject 的绘制添加时间线事件

### 使用说明

1. *[可选]* 在应用的 main 方法中将任意需要的跟踪标志设置为 true。
2. 在 [profile 模式]($profileModeLink) 下运行你的 Flutter Web 应用。
3. 打开你的应用对应的 [Chrome DevTools 的 Performance 面板]($performancePanelLink)，并开始录制以捕获时间线事件。
''';

const dartWebInstructionsMd =
    '''
## 如何使用 Chrome DevTools 进行性能分析

通过 `dart:developer` 的 [Timeline]($timelineLink) 和
[TimelineTask]($timelineTaskLink) API 发出的任何事件，都会在 Chrome DevTools 的 Performance 面板中展示。

打开你的应用对应的 [Chrome DevTools 的 Performance 面板]($performancePanelLink)，并开始录制以捕获时间线事件。
''';
