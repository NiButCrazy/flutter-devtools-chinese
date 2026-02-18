// Copyright 2022 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../../../shared/analytics/constants.dart' as gac;
import '../../../../shared/globals.dart';
import '../../../../shared/primitives/simple_items.dart';
import '../../../../shared/ui/common_widgets.dart';
import '../../shared/widgets/shared_memory_widgets.dart';
import 'class_table.dart';
import 'tracing_pane_controller.dart';
import 'tracing_tree.dart';

class TracingPane extends StatefulWidget {
  const TracingPane({super.key, required this.controller});

  final TracePaneController controller;

  @override
  State<TracingPane> createState() => TracingPaneState();
}

class TracingPaneState extends State<TracingPane> {
  @override
  void initState() {
    super.initState();

    unawaited(widget.controller.initialize());
  }

  @override
  void didUpdateWidget(TracingPane oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      unawaited(widget.controller.initialize());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfileMode =
        serviceConnection.serviceManager.connectedApp?.isProfileBuildNow ??
        false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TracingControls(
          isProfileMode: isProfileMode,
          controller: widget.controller,
        ),
        Expanded(
          child: OutlineDecoration.onlyTop(
            child: SplitPane(
              axis: Axis.horizontal,
              initialFractions: const [0.25, 0.75],
              children: [
                OutlineDecoration.onlyRight(
                  child: AllocationTracingTable(controller: widget.controller),
                ),
                OutlineDecoration.onlyLeft(
                  child: AllocationTracingTree(controller: widget.controller),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TracingControls extends StatelessWidget {
  const _TracingControls({
    required this.isProfileMode,
    required this.controller,
  });

  final bool isProfileMode;

  final TracePaneController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(denseSpacing),
      child: Row(
        children: [
          if (!offlineDataController.showingOfflineData.value) ...[
            RefreshButton(
              tooltip: '请求更新后的分配追踪集合',
              gaScreen: gac.memory,
              gaSelection: gac.MemoryEvents.tracingRefresh.name,
              onPressed: isProfileMode ? null : controller.refresh,
            ),
            const SizedBox(width: denseSpacing),
            ClearButton(
              tooltip: '清除之前收集的追踪数据集合',
              gaScreen: gac.memory,
              gaSelection: gac.MemoryEvents.tracingClear.name,
              onPressed: isProfileMode ? null : controller.clear,
            ),
            const SizedBox(width: denseSpacing),
          ],
          const _ProfileHelpLink(),
        ],
      ),
    );
  }
}

class _ProfileHelpLink extends StatelessWidget {
  const _ProfileHelpLink();

  static final _documentationTopic = gac.MemoryEvents.tracingHelp.name;

  @override
  Widget build(BuildContext context) {
    return HelpButtonWithDialog(
      gaScreen: gac.memory,
      gaSelection: gac.topicDocumentationButton(_documentationTopic),
      dialogTitle: '内存分配追踪帮助',
      actions: [
        MoreInfoLink(
          url: DocLinks.trace.value,
          gaScreenName: gac.memory,
          gaSelectedItemDescription: gac.topicDocumentationLink(
            _documentationTopic,
          ),
        ),
      ],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '分配追踪标签页允许您为特定类型切换分配追踪开关，\n'
            '它会记录当前选中 isolate 中，被追踪类型的实例在哪些\n'
            '位置发生了分配。\n'
            '\n'
            '您可以通过刷新追踪剖析信息来查看被追踪类型的\n'
            '分配位置。然后从列表中选择该类型，即可查看对象\n'
            '被分配位置的精简视图。',
          ),
          SizedBox(height: denseSpacing),
          ClassTypeLegend(),
        ],
      ),
    );
  }
}
