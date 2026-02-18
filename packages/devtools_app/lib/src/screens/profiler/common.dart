// Copyright 2023 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:flutter/foundation.dart';

enum ProfilerTab {
  bottomUp('自下而上', _bottomUpTab),
  callTree('调用树', _callTreeTab),
  methodTable('方法表', _methodTableTab),
  cpuFlameChart('火焰图', _flameChartTab);

  const ProfilerTab(this.title, this.key);

  final String title;
  final Key key;

  // When content of the selected DevToolsTab from the tab controller has any
  // of these three keys, we will not show the expand/collapse buttons.
  static const _flameChartTab = Key('cpu profile flame chart tab');
  static const _methodTableTab = Key('cpu profile method table tab');

  static const _bottomUpTab = Key('cpu profile bottom up tab');
  static const _callTreeTab = Key('cpu profile call tree tab');

  static ProfilerTab byKey(Key? k) {
    return ProfilerTab.values.firstWhere((tab) => tab.key == k);
  }
}
