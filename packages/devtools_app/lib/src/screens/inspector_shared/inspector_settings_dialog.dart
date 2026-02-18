// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:vm_service/vm_service.dart' hide Stack;

import '../../shared/analytics/analytics.dart' as ga;
import '../../shared/analytics/constants.dart' as gac;
import '../../shared/feature_flags.dart';
import '../../shared/globals.dart';
import '../../shared/preferences/preferences.dart';
import '../../shared/primitives/simple_items.dart';
import '../../shared/ui/common_widgets.dart';
import '../../shared/ui/editable_list.dart';

class FlutterInspectorSettingsDialog extends StatelessWidget {
  const FlutterInspectorSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const dialogHeight = 500.0;

    return ValueListenableBuilder(
      valueListenable: preferences.inspector.legacyInspectorEnabled,
      builder: (context, legacyInspectorEnabled, _) {
        final inspectorV2Enabled = !legacyInspectorEnabled;
        return DevToolsDialog(
          title: const DialogTitleText('Flutter 检查器设置'),
          content: SizedBox(
            width: defaultDialogWidth,
            height: dialogHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...dialogSubHeader(theme, '常规'),
                CheckboxSetting(
                  notifier:
                      preferences.inspector.hoverEvalModeEnabled
                          as ValueNotifier<bool?>,
                  title: '启用 hover 检测',
                  description:
                      '将鼠标悬停在任意组件上，会显示该组件的属性和值。',
                  gaItem: gac.inspectorHoverEvalMode,
                ),
                const SizedBox(height: largeSpacing),
                if (inspectorV2Enabled) ...[
                  CheckboxSetting(
                    notifier:
                        preferences.inspector.autoRefreshEnabled
                            as ValueNotifier<bool?>,
                    title: '启用组件树自动刷新',
                    description:
                        '在热重载或导航操作后，组件树将自动刷新',
                    gaItem: gac.inspectorAutoRefreshEnabled,
                  ),
                ] else ...[
                  const InspectorDefaultDetailsViewOption(),
                ],
                const SizedBox(height: largeSpacing),
                // TODO(https://github.com/flutter/devtools/issues/7860): Clean-up
                // after Inspector V2 has been released.
                if (FeatureFlags.inspectorV2.isEnabled)
                  Flexible(
                    child: CheckboxSetting(
                      notifier:
                          preferences.inspector.legacyInspectorEnabled
                              as ValueNotifier<bool?>,
                      title: '使用旧版检查器（未汉化）',
                      description:
                          '禁用重新设计的新版 Flutter 检查器。请注意，旧版检查器可能会在未来的版本中被移除',
                      gaItem: gac.inspectorV2Disabled,
                    ),
                  ),
                const SizedBox(height: largeSpacing),
                ...dialogSubHeader(theme, '包目录'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '这些目录中的组件将会显示在您的组件树中',
                        style: theme.subtleTextStyle,
                      ),
                    ),
                    MoreInfoLink(
                      url: DocLinks.inspectorPackageDirectories.value,
                      gaScreenName: gac.inspector,
                      gaSelectedItemDescription:
                          gac.InspectorDocs.packageDirectoriesDocs.name,
                    ),
                  ],
                ),
                Text(
                  '（例如：/absolute/path/to/myPackage/）',
                  style: theme.subtleTextStyle,
                ),
                const SizedBox(height: denseSpacing),
                const Expanded(child: PubRootDirectorySection()),
              ],
            ),
          ),
          actions: const [DialogCloseButton()],
        );
      },
    );
  }
}

class InspectorDefaultDetailsViewOption extends StatelessWidget {
  const InspectorDefaultDetailsViewOption({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: preferences.inspector.defaultDetailsView,
      builder: (context, selection, _) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择检查器的默认标签页',
              style: theme.subtleTextStyle,
            ),
            const SizedBox(height: denseSpacing),
            RadioGroup(
              groupValue: selection,
              onChanged: _onChanged,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Radio<InspectorDetailsViewType>(
                    value: InspectorDetailsViewType.layoutExplorer,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(InspectorDetailsViewType.layoutExplorer.key),
                  const SizedBox(width: denseSpacing),
                  const Radio<InspectorDetailsViewType>(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: InspectorDetailsViewType.widgetDetailsTree,
                  ),
                  Text(InspectorDetailsViewType.widgetDetailsTree.key),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _onChanged(InspectorDetailsViewType? value) {
    if (value != null) {
      preferences.inspector.setDefaultInspectorDetailsView(value);
      final item = value.name == InspectorDetailsViewType.layoutExplorer.name
          ? gac.defaultDetailsViewToLayoutExplorer
          : gac.defaultDetailsViewToWidgetDetails;
      ga.select(gac.inspector, item);
    }
  }
}

class PubRootDirectorySection extends StatelessWidget {
  const PubRootDirectorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IsolateRef?>(
      valueListenable:
          serviceConnection.serviceManager.isolateManager.mainIsolate,
      builder: (_, _, _) {
        return SizedBox(
          height: 200.0,
          child: EditableList(
            gaScreen: gac.inspector,
            gaRefreshSelection: gac.refreshPubRoots,
            entries: preferences.inspector.pubRootDirectories,
            textFieldLabel: '输入一个新的包目录',
            isRefreshing: preferences.inspector.isRefreshingPubRootDirectories,
            onEntryAdded: (p0) => unawaited(
              preferences.inspector.addPubRootDirectories([
                p0,
              ], shouldCache: true),
            ),
            onEntryRemoved: (p0) =>
                unawaited(preferences.inspector.removePubRootDirectories([p0])),
            onRefreshTriggered: () =>
                unawaited(preferences.inspector.loadPubRootDirectories()),
          ),
        );
      },
    );
  }
}
