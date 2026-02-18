// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../service/service_extension_widgets.dart';
import '../../shared/analytics/constants.dart' as gac;
import '../../shared/globals.dart';
import '../../shared/primitives/utils.dart';
import '../../shared/ui/common_widgets.dart';
import '../../shared/ui/filter.dart';
import '../../shared/ui/search.dart';
import 'logging_controller.dart';

const _loggingMinVerboseWidth = 650.0;

class LoggingControls extends StatelessWidget {
  const LoggingControls({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = screenControllers.lookup<LoggingController>();
    return Row(
      children: [
        ClearButton(
          onPressed: controller.clear,
          gaScreen: gac.logging,
          gaSelection: gac.clear,
          minScreenWidthForText: _loggingMinVerboseWidth,
        ),
        const SizedBox(width: denseSpacing),
        Expanded(
          // TODO(kenz): fix focus issue when state is refreshed
          child: ValueListenableBuilder(
            valueListenable: controller.filteredData,
            builder: (context, _, _) => SearchField<LoggingController>(
              searchFieldWidth:
                  isScreenWiderThan(context, _loggingMinVerboseWidth)
                  ? wideSearchFieldWidth
                  : defaultSearchFieldWidth,
              searchController: controller,
              searchFieldEnabled: controller.filteredData.value.isNotEmpty,
            ),
          ),
        ),
        const SizedBox(width: denseSpacing),
        Expanded(
          child: StandaloneFilterField<LogData>(
            controller: controller,
            filteredItem: 'log',
          ),
        ),
        const SizedBox(width: denseSpacing),
        CopyToClipboardControl(
          dataProvider: () => controller.filteredData.value
              .map((e) => '${e.timestamp} [${e.kind}] ${e.prettyPrinted()}')
              .joinWithTrailing('\n'),
          tooltip: '复制过滤后的日志',
        ),
        const SizedBox(width: denseSpacing),
        SettingsOutlinedButton(
          gaScreen: gac.logging,
          gaSelection: gac.loggingSettings,
          tooltip: '日志设置',
          onPressed: () {
            unawaited(
              showDialog(
                context: context,
                builder: (context) => const LoggingSettingsDialog(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class LoggingSettingsDialog extends StatefulWidget {
  const LoggingSettingsDialog({super.key});

  @override
  State<LoggingSettingsDialog> createState() => _LoggingSettingsDialogState();
}

class _LoggingSettingsDialogState extends State<LoggingSettingsDialog> {
  static const _retentionLimitHeight = 48.0;

  final temporaryRetentionLimit = ValueNotifier<int>(
    preferences.logging.retentionLimit.value,
  );

  @override
  void dispose() {
    temporaryRetentionLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DevToolsDialog(
      title: const DialogTitleText('日志设置'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _retentionLimitHeight,
            child: PositiveIntegerSetting(
              title: '日志保留数量上限',
              subTitle:
                  '达到上限后，将移除最早的 '
                  '$defaultLogBufferReductionSize 条日志',
              notifier: temporaryRetentionLimit,
              minimumValue: defaultLogBufferReductionSize,
            ),
          ),
          const StructuredErrorsToggle(),
        ],
      ),
      actions: [
        DialogApplyButton(
          onPressed: () {
            preferences.logging.retentionLimit.value =
                temporaryRetentionLimit.value;
          },
        ),
        const DialogCloseButton(),
      ],
    );
  }
}
