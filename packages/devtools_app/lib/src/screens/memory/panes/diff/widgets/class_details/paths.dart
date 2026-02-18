// Copyright 2022 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:flutter/widgets.dart';

import '../../../../../../shared/analytics/analytics.dart' as ga;
import '../../../../../../shared/analytics/constants.dart' as gac;
import '../../../../../../shared/memory/classes.dart';
import '../../../../../../shared/primitives/byte_utils.dart';
import '../../../../../../shared/primitives/utils.dart';
import '../../../../../../shared/table/table.dart';
import '../../../../../../shared/table/table_data.dart';
import '../../../../shared/primitives/simple_elements.dart';
import '../../controller/class_data.dart';

class _RetainingPathColumn extends ColumnData<PathData> {
  const _RetainingPathColumn(String className)
    : super.wide(
        '针对 $className 实例的最短保留路径',
        titleTooltip:
            '从垃圾回收中保留 $className 实例的\n'
            '最短对象链路',
        alignment: ColumnAlignment.left,
      );

  @override
  String? getValue(PathData record) =>
      record.path.toShortString(inverted: true);

  @override
  String getTooltip(PathData record) => '';
}

class _InstanceColumn extends ColumnData<PathData> {
  const _InstanceColumn(bool isDiff)
    : super(
        isDiff ? '实例\n变化量' : '实例数',
        titleTooltip:
            '该路径所保留的类实例数量',
        fixedWidthPx: 80.0,
        alignment: ColumnAlignment.right,
      );

  @override
  int getValue(PathData record) => record.objects.instanceCount;

  @override
  bool get numeric => true;
}

class _ShallowSizeColumn extends ColumnData<PathData> {
  _ShallowSizeColumn(bool isDiff)
    : super(
        isDiff ? '浅层\n大小变化量' : '浅层\nDart 大小',
        titleTooltip: SizeType.shallow.description,
        fixedWidthPx: 80.0,
        alignment: ColumnAlignment.right,
      );

  @override
  int getValue(PathData record) => record.objects.shallowSize;

  @override
  bool get numeric => true;

  @override
  String getDisplayValue(PathData record) =>
      prettyPrintBytes(getValue(record), includeUnit: true)!;
}

class _RetainedSizeColumn extends ColumnData<PathData> {
  _RetainedSizeColumn(bool isDiff)
    : super(
        isDiff ? '保留\n大小变化量' : '保留\nDart 大小',
        titleTooltip: SizeType.retained.description,
        fixedWidthPx: 80.0,
        alignment: ColumnAlignment.right,
      );

  @override
  int getValue(PathData record) => record.objects.retainedSize;

  @override
  bool get numeric => true;

  @override
  String getDisplayValue(PathData record) =>
      prettyPrintBytes(getValue(record), includeUnit: true)!;
}

class _RetainingPathTableColumns {
  _RetainingPathTableColumns(this.isDiff, this.className);

  final bool isDiff;

  final String className;

  late final retainedSizeColumn = _RetainedSizeColumn(isDiff);

  late final columnList = <ColumnData<PathData>>[
    _RetainingPathColumn(className),
    _InstanceColumn(isDiff),
    _ShallowSizeColumn(isDiff),
    retainedSizeColumn,
  ];
}

class RetainingPathTable extends StatelessWidget {
  RetainingPathTable({
    super.key,
    required this.classData,
    required this.selection,
    required this.isDiff,
  });

  final ValueNotifier<PathData?> selection;
  final bool isDiff;
  final ClassData classData;

  late final _data = toPathDataList(classData);

  @visibleForTesting
  static List<PathData> toPathDataList(ClassData classData) =>
      classData.byPath.keys.map((path) => PathData(classData, path)).toList();

  static final _columnStore = <String, _RetainingPathTableColumns>{};
  static _RetainingPathTableColumns _columns(
    String dataKey,
    bool isDiff,
    String className,
  ) => _columnStore.putIfAbsent(
    dataKey,
    () => _RetainingPathTableColumns(isDiff, className),
  );

  @override
  Widget build(BuildContext context) {
    final dataKey =
        'RetainingPathTable-$isDiff-${classData.className.fullName}';
    final columns = _columns(dataKey, isDiff, classData.className.shortName);
    return FlatTable<PathData>(
      dataKey: dataKey,
      columns: columns.columnList,
      data: _data,
      keyFactory: (e) => ValueKey(e.path),
      selectionNotifier: selection,
      onItemSelected: (_) => ga.select(
        gac.memory,
        '${gac.MemoryEvents.diffPathSelect.name}-${isDiff ? "diff" : "single"}',
      ),
      defaultSortColumn: columns.retainedSizeColumn,
      defaultSortDirection: SortDirection.descending,
      tallHeaders: true,
    );
  }
}
