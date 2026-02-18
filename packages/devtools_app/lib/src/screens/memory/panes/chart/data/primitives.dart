// Copyright 2022 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:collection/collection.dart';

/// Automatic pruning of collected memory statistics (plotted) full data is
/// still retained. Default is the best view each tick is 10 pixels, the
/// width of an event symbol e.g., snapshot, monitor, etc.
enum ChartInterval {
  theDefault(Duration.zero, '默认'),
  oneMinute(Duration(minutes: 1), '1 分钟'),
  fiveMinutes(Duration(minutes: 5), '5 分钟'),
  tenMinutes(Duration(minutes: 10), '10 分钟'),
  all(null, '全部');

  const ChartInterval(this.duration, this.displayName);

  final Duration? duration;

  final String displayName;

  static ChartInterval? byName(String name) {
    return values.firstWhereOrNull((i) => i.name == name);
  }
}

const chartUpdateDelay = Duration(milliseconds: 500);
