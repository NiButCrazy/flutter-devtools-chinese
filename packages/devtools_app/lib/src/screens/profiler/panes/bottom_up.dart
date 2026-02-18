// Copyright 2020 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../../shared/primitives/utils.dart';
import '../../../shared/table/table.dart';
import '../../../shared/table/table_data.dart';
import '../cpu_profile_model.dart';
import 'cpu_profile_columns.dart';

/// A table of the bottom up tree for a CPU profile.
class CpuBottomUpTable extends StatelessWidget {
  const CpuBottomUpTable({required this.bottomUpRoots, super.key});

  static const methodColumn = MethodAndSourceColumn();
  static final selfTimeColumn = SelfTimeColumn(
    titleTooltip: selfTimeTooltip,
    dataTooltipProvider: (stackFrame, context) =>
        _bottomUpTimeTooltipBuilder(_TimeType.self, stackFrame, context),
  );
  static final totalTimeColumn = TotalTimeColumn(
    titleTooltip: totalTimeTooltip,
    dataTooltipProvider: (stackFrame, context) =>
        _bottomUpTimeTooltipBuilder(_TimeType.total, stackFrame, context),
  );
  static final columns = List<ColumnData<CpuStackFrame>>.unmodifiable([
    totalTimeColumn,
    selfTimeColumn,
    methodColumn,
  ]);

  static const totalTimeTooltip = '''
对于 Bottom-up 树中的顶层方法（在至少一次 CPU 采样中位于调用栈顶部的帧），
此数值表示该方法执行自身代码的时间，以及其所调用的方法的执行时间

对于 Bottom-up 树中的子方法（调用者），
此数值表示当顶层方法（被调用者）通过该子方法（调用者）被调用时的总耗时''';

  static const selfTimeTooltip = '''
对于 Bottom-up 树中的顶层方法（在至少一次 CPU 采样中位于调用栈顶部的帧），
此数值表示该方法仅执行自身代码所花费的时间

对于 Bottom-up 树中的子方法（调用者），
此数值表示当顶层方法（被调用者）通过该子方法（调用者）被调用时的自身耗时''';

  final List<CpuStackFrame> bottomUpRoots;

  static InlineSpan? _bottomUpTimeTooltipBuilder(
    _TimeType type,
    CpuStackFrame stackFrame,
    BuildContext context,
  ) {
    final fixedStyle = Theme.of(context).tooltipFixedFontStyle;
    if (stackFrame.isRoot) {
      switch (type) {
        case _TimeType.total:
          return TextSpan(
            children: [
              const TextSpan(text: '方法 '),
              TextSpan(text: '[${stackFrame.name}]', style: fixedStyle),
              const TextSpan(
                text:
                    ' 执行自身代码的时间，\n以及它所调用的任何方法的代码执行时间',
              ),
            ],
          );
        case _TimeType.self:
          return TextSpan(
            children: [
              const TextSpan(text: '方法 '),
              TextSpan(text: '[${stackFrame.name}]', style: fixedStyle),
              const TextSpan(text: ' 执行自身代码所花费的时间'),
            ],
          );
      }
    }
    return TextSpan(
      children: [
        TextSpan(text: 'root 节点的 $type 耗时：'),
        TextSpan(text: '[${stackFrame.root.name}]', style: fixedStyle),
        const TextSpan(text: '\n当通过以下方法调用时：'),
        TextSpan(text: '[${stackFrame.name}]', style: fixedStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return TreeTable<CpuStackFrame>(
      keyFactory: (frame) => PageStorageKey<String>(frame.id),
      displayTreeGuidelines: true,
      dataRoots: bottomUpRoots,
      dataKey: 'cpu-bottom-up',
      columns: columns,
      treeColumn: methodColumn,
      defaultSortColumn: selfTimeColumn,
      defaultSortDirection: SortDirection.descending,
    );
  }
}

enum _TimeType {
  self,
  total;

  @override
  String toString() {
    switch (this) {
      case self:
        return 'Self';
      case total:
        return 'Total';
    }
  }
}
