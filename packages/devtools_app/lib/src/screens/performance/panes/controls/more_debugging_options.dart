// Copyright 2022 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../../../service/service_extension_widgets.dart';
import '../../../../service/service_extensions.dart' as extensions;
import '../../../../shared/globals.dart';
import 'performance_controls.dart';

class MoreDebuggingOptionsButton extends StatelessWidget {
  const MoreDebuggingOptionsButton({super.key});

  static const _width = 620.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ServiceExtensionCheckboxGroupButton(
      title: '更多调试选项',
      icon: Icons.build,
      tooltip: '打开可用于帮助调试性能的选项列表',
      minScreenWidthForText: PerformanceControls.minScreenWidthForText,
      extensions: [
        extensions.disableClipLayers,
        extensions.disableOpacityLayers,
        extensions.disablePhysicalShapeLayers,
        extensions.countWidgetBuilds,
      ],
      overlayDescription: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '在开启或关闭某个渲染图层后，请重新在应用中执行相关操作以查看效果。'
            '默认情况下所有图层都会被渲染 —— 禁用某个图层可能帮助您识别应用中开销较大的操作。',
            style: theme.subtleTextStyle,
          ),
          if (serviceConnection
              .serviceManager
              .connectedApp!
              .isProfileBuildNow!) ...[
            const SizedBox(height: denseSpacing),
            RichText(
              text: TextSpan(
                text:
                    '这些调试选项在 Profile 模式下不可用，'
                    '如需使用它们，请在 Debug 模式下运行您的应用',
                style: theme.subtleTextStyle.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ],
      ),
      overlayWidth: _width,
    );
  }
}
