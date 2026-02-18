// Copyright 2023 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/analytics/analytics_controller.dart';
import '../../shared/analytics/constants.dart' as gac;
import '../../shared/config_specific/copy_to_clipboard/copy_to_clipboard.dart';
import '../../shared/feature_flags.dart';
import '../../shared/globals.dart';
import '../../shared/log_storage.dart';
import '../../shared/server/server.dart';
import '../../shared/ui/common_widgets.dart';

class OpenSettingsAction extends ScaffoldAction {
  OpenSettingsAction({super.key, super.color})
    : super(
        icon: Icons.settings_outlined,
        tooltip: '设置',
        onPressed: (context) {
          unawaited(
            showDialog(
              context: context,
              builder: (context) => const SettingsDialog(),
            ),
          );
        },
      );
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analyticsController = Provider.of<AnalyticsController>(context);
    return DevToolsDialog(
      title: const DialogTitleText('设置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEmbedded())
            Flexible(
              child: CheckboxSetting(
                title: '使用深色主题',
                notifier: preferences.darkModeEnabled,
                onChanged: preferences.toggleDarkModeTheme,
                gaScreen: gac.settingsDialog,
                gaItem: gac.darkTheme,
              ),
            ),
          if (isExternalBuild && isDevToolsServerAvailable)
            Flexible(
              child: CheckboxSetting(
                title: '启用分析功能',
                notifier: analyticsController.analyticsEnabled,
                onChanged: (enable) => unawaited(
                  analyticsController.toggleAnalyticsEnabled(enable),
                ),
                gaScreen: gac.settingsDialog,
                gaItem: gac.analytics,
              ),
            ),
          Flexible(
            child: CheckboxSetting(
              title: '启用高级开发者模式',
              notifier: preferences.advancedDeveloperModeEnabled,
              onChanged: preferences.toggleAdvancedDeveloperMode,
              gaScreen: gac.settingsDialog,
              gaItem: gac.vmDeveloperMode,
            ),
          ),
          if (FeatureFlags.wasmOptInSetting.isEnabled) ...[
            const SizedBox(height: largeSpacing),
            ...dialogSubHeader(theme, '实验性功能'),
            Flexible(
              child: CheckboxSetting(
                title: '启用 WebAssembly',
                description:
                    '这将重新加载页面，加载开发者工具'
                    '使用 WebAssembly 编译，这可能会带来更好的性能表现',
                notifier: preferences.wasmEnabled,
                onChanged: preferences.toggleWasmEnabled,
                gaScreen: gac.settingsDialog,
                gaItem: gac.wasm,
              ),
            ),
          ],
          const SizedBox(height: largeSpacing),
          ...dialogSubHeader(theme, '故障检测'),
          const _VerboseLoggingSetting(),
        ],
      ),
      actions: const [DialogCloseButton()],
    );
  }
}

class _VerboseLoggingSetting extends StatelessWidget {
  const _VerboseLoggingSetting();

  static const _minScreenWidthForText = 500.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Flexible(
              child: CheckboxSetting(
                title: '启用详细日志记录',
                notifier: preferences.verboseLoggingEnabled,
                onChanged: (enable) => preferences.toggleVerboseLogging(enable),
                gaScreen: gac.settingsDialog,
                gaItem: gac.verboseLogging,
              ),
            ),
            const SizedBox(width: defaultSpacing),
            GaDevToolsButton(
              label: '复制日志',
              icon: Icons.copy_outlined,
              gaScreen: gac.settingsDialog,
              gaSelection: gac.copyLogs,
              minScreenWidthForText: _minScreenWidthForText,
              onPressed: () async => await copyToClipboard(
                LogStorage.root.toString(),
                successMessage: '日志复制成功',
              ),
            ),
            const SizedBox(width: denseSpacing),
            ClearButton(
              label: '清除日志',
              gaScreen: gac.settingsDialog,
              gaSelection: gac.clearLogs,
              minScreenWidthForText: _minScreenWidthForText,
              onPressed: LogStorage.root.clear,
            ),
          ],
        ),
        const SizedBox(height: denseSpacing),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning),
            SizedBox(width: defaultSpacing),
            Flexible(
              child: Text(
                '日志可能包含敏感信息\n'
                '分享前请务必检查其内容',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
