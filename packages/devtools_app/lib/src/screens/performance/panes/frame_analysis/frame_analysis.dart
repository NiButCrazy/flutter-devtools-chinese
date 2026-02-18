// Copyright 2021 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../service/service_extension_widgets.dart';
import '../../../../service/service_extensions.dart' as extensions;
import '../../../../shared/globals.dart';
import '../../../../shared/primitives/utils.dart';
import '../controls/enhance_tracing/enhance_tracing_controller.dart';
import '../flutter_frames/flutter_frame_model.dart';
import '../rebuild_stats/rebuild_stats.dart';
import '../rebuild_stats/rebuild_stats_model.dart';
import 'frame_hints.dart';
import 'frame_time_visualizer.dart';

class FlutterFrameAnalysisView extends StatelessWidget {
  const FlutterFrameAnalysisView({
    super.key,
    required this.frame,
    required this.enhanceTracingController,
    required this.rebuildCountModel,
    required this.displayRefreshRateNotifier,
  });

  final FlutterFrame frame;

  final EnhanceTracingController enhanceTracingController;

  final RebuildCountModel rebuildCountModel;

  final ValueListenable<double> displayRefreshRateNotifier;

  @override
  Widget build(BuildContext context) {
    final frameAnalysis = frame.frameAnalysis;
    final rebuilds = rebuildCountModel.rebuildsForFrame(frame.id);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(defaultSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Flutter 帧: ',
                  style: theme.regularTextStyle,
                ),
                TextSpan(
                  text: '${frame.id}',
                  style: theme.fixedFontStyle.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const PaddedDivider.noPadding(),
          if (frameAnalysis == null) ...[
            const Text(
              '此帧没有可用的时间线事件分析数据，原因可能是该帧的时间线事件发生时间过久，'
  'DevTools 无法再访问。为避免这种情况，请更早打开 DevTools 的性能页面。',
            ),
          ] else ...[
            // TODO(jacobr): we might have so many frame hints that this content
            // needs to scroll. Supporting that would be hard as the RebuildTable
            // also needs to scroll and the devtools table functionality does not
            // support the shrinkWrap property and has features that would make
            //it difficult to handle robustly.
            ValueListenableBuilder(
              valueListenable: displayRefreshRateNotifier,
              builder: (context, refreshRate, _) {
                return FrameHints(
                  frameAnalysis: frameAnalysis,
                  enhanceTracingController: enhanceTracingController,
                  displayRefreshRate: refreshRate,
                );
              },
            ),

            const PaddedDivider.noPadding(),
            FrameTimeVisualizer(frameAnalysis: frameAnalysis),
          ],
          if (rebuilds.isNullOrEmpty) ...[
            const PaddedDivider.noPadding(),
            ValueListenableBuilder<ServiceExtensionState>(
              valueListenable: serviceConnection
                  .serviceManager
                  .serviceExtensionManager
                  .getServiceExtensionState(
                    extensions.countWidgetBuilds.extension,
                  ),
              builder: (context, extensionState, _) {
                if (!extensionState.enabled) {
                  return Row(
                    children: [
                      const Text(
                        '要查看 Flutter 帧的组件重建，请启用',
                      ),
                      Flexible(
                        child: ServiceExtensionCheckbox(
                          serviceExtension: extensions.countWidgetBuilds,
                          showDescription: false,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ],
          if (rebuilds == null)
            const Text('此帧没有可用的组件重建信息')
          else if (rebuilds.isEmpty)
            const Text(
              '在此帧中，没有发生由您项目中直接创建的组件的重建',
            )
          else ...[
            const SizedBox(height: defaultSpacing),
            Expanded(
              child: RebuildTable(
                metricNames: const ['重建次数'],
                metrics: combineStats([rebuilds]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
