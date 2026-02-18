// Copyright 2019 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/analytics/analytics.dart' as ga;
import '../../../../../shared/analytics/constants.dart' as gac;
import '../../../../../shared/globals.dart';
import '../../../../../shared/primitives/simple_items.dart';
import '../../../../../shared/ui/common_widgets.dart';
import '../../../shared/primitives/simple_elements.dart';
import '../controller/chart_pane_controller.dart';
import 'interval_dropdown.dart';

class ChartControlPane extends StatefulWidget {
  const ChartControlPane({super.key, required this.chart});

  final MemoryChartPaneController chart;

  @override
  State<ChartControlPane> createState() => _ChartControlPaneState();
}

@visibleForTesting
class ChartPaneTooltips {
  static const pauseTooltip =
      '暂停图表，数据仍会被收集，并在恢复时显示。';
  static const resumeTooltip = '恢复图表';
}

class _ChartControlPaneState extends State<ChartControlPane>
    with AutoDisposeMixin {
  void _onPause() {
    ga.select(gac.memory, gac.pause);
    widget.chart.pause();
  }

  void _onResume() {
    ga.select(gac.memory, gac.resume);
    widget.chart.resume();
  }

  void _clearTimeline() {
    ga.select(gac.memory, gac.clear);

    widget.chart.data.timeline.reset();

    // Remove history of all plotted data in all charts.
    widget.chart.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!offlineDataController.showingOfflineData.value) ...[
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: widget.chart.paused,
                builder: (context, paused, _) {
                  return PauseResumeButtonGroup(
                    paused: paused,
                    onPause: _onPause,
                    onResume: _onResume,
                    pauseTooltip: ChartPaneTooltips.pauseTooltip,
                    resumeTooltip: ChartPaneTooltips.resumeTooltip,
                    gaScreen: gac.memory,
                    gaSelectionPause: gac.MemoryEvents.pauseChart.name,
                    gaSelectionResume: gac.MemoryEvents.resumeChart.name,
                  );
                },
              ),
              const SizedBox(width: defaultSpacing),
              ClearButton(
                onPressed: _clearTimeline,
                tooltip: '清除内存图表',
                gaScreen: gac.memory,
                gaSelection: gac.MemoryEvents.clearChart.name,
                iconOnly: true,
              ),
            ],
          ),
        ],
        const SizedBox(height: denseSpacing),
        Row(children: [_LegendButton(chartController: widget.chart)]),
        const SizedBox(height: denseSpacing),
        IntervalDropdown(chartController: widget.chart),
        const SizedBox(height: denseSpacing),
        const _ChartHelpLink(),
      ],
    );
  }
}

class _LegendButton extends StatelessWidget {
  const _LegendButton({required this.chartController});

  final MemoryChartPaneController chartController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: chartController.data.isLegendVisible,
      builder: (_, legendVisible, _) => GaDevToolsButton(
        onPressed: chartController.data.toggleLegendVisibility,
        gaScreen: gac.memory,
        gaSelection: legendVisible
            ? gac.MemoryEvents.hideChartLegend.name
            : gac.MemoryEvents.showChartLegend.name,
        icon: legendVisible ? Icons.close : Icons.storage,
        label: '图例',
        tooltip: '切换图表图例的可见性',
        minScreenWidthForText: memoryControlsMinVerboseWidth,
      ),
    );
  }
}

class _ChartHelpLink extends StatelessWidget {
  const _ChartHelpLink();

  static final _documentationTopic = gac.MemoryEvents.chartHelp.name;

  @override
  Widget build(BuildContext context) {
    return HelpButtonWithDialog(
      gaScreen: gac.memory,
      gaSelection: gac.topicDocumentationButton(_documentationTopic),
      dialogTitle: '内存图表帮助',
      actions: [
        MoreInfoLink(
          url: DocLinks.chart.value,
          gaScreenName: '',
          gaSelectedItemDescription: gac.topicDocumentationLink(
            _documentationTopic,
          ),
        ),
      ],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '内存图表显示应用程序的实时和历史内存使用统计信息',
          ),
        ],
      ),
    );
  }
}
