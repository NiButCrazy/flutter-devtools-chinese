// Copyright 2022 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/widgets.dart';

import '../../../../../../shared/memory/classes.dart';
import '../../../../../../shared/ui/common_widgets.dart';
import '../../controller/class_data.dart';
import 'path.dart';
import 'paths.dart';

class HeapClassDetails extends StatelessWidget {
  const HeapClassDetails({
    super.key,
    required this.classData,
    required this.pathSelection,
    required this.isDiff,
    required this.pathController,
  });

  final ClassData? classData;
  final ValueNotifier<PathData?> pathSelection;
  final RetainingPathController pathController;
  final bool isDiff;

  @override
  Widget build(BuildContext context) {
    final data = classData;
    if (data == null) {
      return const CenteredMessage(
        message: '点击表格行以在此查看保留链路',
      );
    }

    final retainingPathsTable = RetainingPathTable(
      classData: data,
      selection: pathSelection,
      isDiff: isDiff,
    );

    final selectedPathView = ValueListenableBuilder<PathData?>(
      valueListenable: pathSelection,
      builder: (_, pathData, _) {
        if (pathData == null) {
          return const CenteredMessage(
            message: '点击表格行以查看详细链路',
          );
        }

        return RetainingPathView(data: pathData, controller: pathController);
      },
    );

    return SplitPane(
      axis: Axis.horizontal,
      initialFractions: const [0.7, 0.3],
      children: [
        OutlineDecoration.onlyRight(child: retainingPathsTable),
        OutlineDecoration.onlyLeft(child: selectedPathView),
      ],
    );
  }
}
