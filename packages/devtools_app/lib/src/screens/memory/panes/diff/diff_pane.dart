// Copyright 2022 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../shared/analytics/constants.dart' as gac;
import '../../../../shared/primitives/simple_items.dart';
import '../../../../shared/ui/common_widgets.dart';
import '../../../../shared/utils/utils.dart';
import '../../shared/widgets/shared_memory_widgets.dart';
import 'controller/diff_pane_controller.dart';
import 'controller/snapshot_item.dart';
import 'widgets/snapshot_control_pane.dart';
import 'widgets/snapshot_list.dart';
import 'widgets/snapshot_view.dart';

class DiffPane extends StatelessWidget {
  const DiffPane({super.key, required this.diffController});

  final DiffPaneController diffController;

  @override
  Widget build(BuildContext context) {
    return SplitPane(
      axis: Axis.horizontal,
      initialFractions: const [0.1, 0.9],
      minSizes: const [80, 80],
      children: [
        OutlineDecoration.onlyRight(
          child: SnapshotList(controller: diffController),
        ),
        OutlineDecoration.onlyLeft(
          child: _SnapshotItemContent(controller: diffController),
        ),
      ],
    );
  }
}

class _SnapshotItemContent extends StatelessWidget {
  const _SnapshotItemContent({required this.controller});

  final DiffPaneController controller;

  static final _documentationTopic = gac.MemoryEvents.diffHelp.name;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SnapshotItem>(
      valueListenable: controller.derived.selectedItem,
      builder: (_, item, _) {
        if (item is SnapshotDocItem) {
          return Padding(
            padding: const EdgeInsets.all(denseSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Markdown(
                          data: _snapshotDocumentation(
                            isDark: isDarkThemeEnabled(),
                          ),
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).regularTextStyle,
                          ),
                          onTapLink: (text, url, title) =>
                              unawaited(launchUrlWithErrorHandling(url!)),
                        ),
                      ),
                      const SizedBox(width: densePadding),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                              top: defaultSpacing,
                              right: denseSpacing,
                            ),
                            child: ClassTypeLegend(),
                          ),
                          MoreInfoLink(
                            url: DocLinks.diff.value,
                            gaScreenName: gac.memory,
                            gaSelectedItemDescription: gac
                                .topicDocumentationLink(_documentationTopic),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SnapshotInstanceItemPane(controller: controller);
      },
    );
  }
}

@visibleForTesting
class SnapshotInstanceItemPane extends StatelessWidget {
  const SnapshotInstanceItemPane({super.key, required this.controller});

  final DiffPaneController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlineDecoration.onlyBottom(
          child: Padding(
            padding: const EdgeInsets.all(denseSpacing),
            child: SnapshotControlPane(controller: controller),
          ),
        ),
        Expanded(child: SnapshotView(controller: controller)),
      ],
    );
  }
}

String _snapshotDocumentation({required bool isDark}) {
  final filePostfix = isDark ? 'dark' : 'light';

  // TODO(polina-c): remove after fixing https://github.com/flutter/flutter/issues/149866
  const isWebProd = kIsWeb && !kDebugMode;
  const imagePath = isWebProd ? 'assets/' : '';
  final uploadImageUrl = '${imagePath}assets/img/doc/upload_$filePostfix.png';

  // `\v` adds vertical space
return '''
通过比较两个堆快照来查找意外的内存使用情况：

\v

1. 了解 [Dart 内存概念](https://docs.flutter.cn/tools/devtools/memory#basic-memory-concepts)。

\v

2. 通过以下方式之一获取 **堆快照**：

    a. 要为已连接的应用程序生成快照，请点击 ● 按钮

    b. 要导入从 DevTools 导出的快照，或使用
    [auto-snapshotting](https://github.com/dart-lang/leak_tracker/blob/main/doc/USAGE.md)、
    [writeHeapSnapshotToFile](https://api.flutter.dev/flutter/dart-developer/NativeRuntime/writeHeapSnapshotToFile.html)
    生成的快照，请点击 ![import]($uploadImageUrl) 按钮

\v

3. 查看快照：

    b. 若需要精确结果，请使用 **Filter**（过滤）按钮

    c. 从快照表格中选择某个类以查看其保留链路（retaining paths）

    d. 在 **最短保留链路…** 表格中选择条目查看保留链路详情

\v

4. 对比两个快照的 **diff** 来检测内存分配问题：

    a. 在某个功能执行前后分别获取 **快照**。
       如果由于快照过大导致 DevTools 崩溃，
       请切换到 [桌面版](https://github.com/flutter/devtools/blob/master/BETA_TESTING.md)。

    b. 查看第二个快照时，点击 **对比快照:** 并在下拉菜单中选择第一个快照；
       结果区域将显示差异

    c. 如有需要，可使用 **Filter**（过滤）按钮进一步筛选 diff 结果

    d. 从 diff 中选择某个类以查看其保留链路，了解哪些对象持有这些实例的引用
''';
}
