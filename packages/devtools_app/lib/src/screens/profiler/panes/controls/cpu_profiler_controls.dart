// Copyright 2023 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:developer';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../../../shared/globals.dart';
import '../../cpu_profiler_controller.dart';

/// [RoundedDropDownButton] that controls the value of
/// [CpuProfilerController._userTagFilter].
class UserTagDropdown extends StatelessWidget {
  const UserTagDropdown(this.controller, {super.key});

  final CpuProfilerController controller;

  @override
  Widget build(BuildContext context) {
    const filterByTag = '按标签过滤: ';
    return ValueListenableBuilder<String>(
      valueListenable: controller.userTagFilter,
      builder: (context, userTag, _) {
        final userTags = controller.userTags;
        final tooltip = userTags.isNotEmpty
            ? '根据指定的 UserTag 过滤 CPU 分析数据'
            : '未找到可用于此 CPU 分析的 UserTag';
        return SizedBox(
          height: defaultButtonHeight,
          child: DevToolsTooltip(
            message: tooltip,
            child: ValueListenableBuilder<bool>(
              valueListenable: preferences.advancedDeveloperModeEnabled,
              builder: (context, advancedDeveloperModeEnabled, _) {
                return RoundedDropDownButton<String>(
                  isDense: true,
                  value: userTag,
                  items: [
                    _buildMenuItem(
                      display:
                          '$filterByTag ${CpuProfilerController.userTagNone}',
                      value: CpuProfilerController.userTagNone,
                    ),
                    // We don't want to show the 'Default' tag if it is the only
                    // tag available. The 'none' tag above is equivalent in this
                    // case.
                    if (!(userTags.length == 1 &&
                        userTags.first == UserTag.defaultTag.label)) ...[
                      for (final tag in userTags)
                        _buildMenuItem(
                          display: '$filterByTag $tag',
                          value: tag,
                        ),
                      _buildMenuItem(
                        display: '组别: User Tag',
                        value: CpuProfilerController.groupByUserTag,
                      ),
                    ],
                    if (advancedDeveloperModeEnabled)
                      _buildMenuItem(
                        display: '组别: VM Tag',
                        value: CpuProfilerController.groupByVmTag,
                      ),
                  ],
                  onChanged:
                      userTags.isEmpty ||
                          (userTags.length == 1 &&
                              userTags.first == UserTag.defaultTag.label)
                      ? null
                      : (String? tag) => _onUserTagChanged(tag!),
                );
              },
            ),
          ),
        );
      },
    );
  }

  DropdownMenuItem<String> _buildMenuItem({
    required String display,
    required String value,
  }) {
    return DropdownMenuItem<String>(value: value, child: Text(display));
  }

  void _onUserTagChanged(String newTag) async {
    try {
      await controller.loadDataWithTag(newTag);
    } catch (e) {
      notificationService.push(e.toString());
    }
  }
}

/// DropdownButton that controls the value of
/// [CpuProfilerController._viewType].
class ModeDropdown extends StatelessWidget {
  const ModeDropdown(this.controller, {super.key});

  final CpuProfilerController controller;

  @override
  Widget build(BuildContext context) {
    const mode = '视图：';
    return ValueListenableBuilder<CpuProfilerViewType>(
      valueListenable: controller.viewType,
      builder: (context, viewType, _) {
        final tooltip = viewType == CpuProfilerViewType.function
            ? '以 Dart 调用栈的方式展示概要（即展开内联帧）'
            : '以原生栈帧的方式展示概要（即不展开内联帧，并显示代码对象而非单个函数）';
        return SizedBox(
          height: defaultButtonHeight,
          child: DevToolsTooltip(
            message: tooltip,
            child: RoundedDropDownButton<CpuProfilerViewType>(
              isDense: true,
              value: viewType,
              items: [
                _buildMenuItem(
                  display: '$mode ${CpuProfilerViewType.function}',
                  value: CpuProfilerViewType.function,
                ),
                _buildMenuItem(
                  display: '$mode ${CpuProfilerViewType.code}',
                  value: CpuProfilerViewType.code,
                ),
              ],
              onChanged: (type) => controller.updateViewForType(type!),
            ),
          ),
        );
      },
    );
  }

  DropdownMenuItem<CpuProfilerViewType> _buildMenuItem({
    required String display,
    required CpuProfilerViewType value,
  }) {
    return DropdownMenuItem<CpuProfilerViewType>(
      value: value,
      child: Text(display),
    );
  }
}
