// Copyright 2022 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

const nonGcableInstancesColumnTooltip =
    '类中可达实例的数量，\n'
    '即从根节点存在引用链的实例，\n'
    '因此无法被垃圾回收';

/// When to have verbose Dropdown based on media width.
const memoryControlsMinVerboseWidth = 240.0;

enum SizeType {
  shallow(
    displayName: '浅层',
    description:
        '所有实例的浅层大小总和。\n'
        '对象的浅层大小是对象本身的大小，\n'
        '加上其字段中持有的对其他 Dart 对象的引用的大小\n'
        '（不包含被引用对象字段的大小，仅包含引用本身的大小）',
  ),
  retained(
    displayName: '保留',
    description:
        '对象的浅层 Dart 大小，加上它所保留的对象的浅层 Dart 大小总和，\n'
        '并且仅考虑这些对象的最短保留路径',
  );

  const SizeType({required this.displayName, required this.description});

  final String displayName;
  final String description;
}