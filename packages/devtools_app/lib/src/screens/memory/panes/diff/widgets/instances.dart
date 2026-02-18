// Copyright 2023 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../shared/analytics/constants.dart';
import '../../../../../shared/memory/class_name.dart';
import '../../../../../shared/memory/classes.dart';
import '../../../../../shared/memory/heap_object.dart';
import '../../../shared/heap/sampler.dart';
import '../../../shared/primitives/instance_context_menu.dart';

/// Right aligned table cell, shat shows number of instances.
///
/// If the row is selected and count of instances is positive, the table cell
/// includes a "more" icon button with a context menu for the instance set.
class HeapInstanceTableCell extends StatelessWidget {
  HeapInstanceTableCell(
    ObjectSet objects,
    HeapDataCallback heap,
    HeapClassName heapClass, {
    super.key,
    required bool isSelected,
    this.liveItemsEnabled = true,
  }) : _sampleObtainer = _shouldShowMenu(isSelected, objects)
           ? SnapshotClassSampler(heapClass, objects, heap())
           : null,
       _count = objects.instanceCount;

  static bool _shouldShowMenu(bool isSelected, ObjectSet objects) =>
      isSelected && objects.instanceCount > 0;

  final SnapshotClassSampler? _sampleObtainer;

  final int _count;
  final bool liveItemsEnabled;

  @override
  Widget build(BuildContext context) {
    return InstanceViewWithContextMenu(
      count: _count,
      menuBuilder: () => _buildHeapInstancesMenu(
        sampler: _sampleObtainer,
        liveItemsEnabled: liveItemsEnabled,
      ),
    );
  }
}

List<Widget> _buildHeapInstancesMenu({
  required SnapshotClassSampler? sampler,
  required bool liveItemsEnabled,
}) {
  if (sampler == null) return [];
  return [
    _StoreAsOneVariableMenu(sampler, liveItemsEnabled: liveItemsEnabled),
    _StoreAllAsVariableMenu(sampler, liveItemsEnabled: liveItemsEnabled),
  ];
}

class _StoreAllAsVariableMenu extends StatelessWidget {
  const _StoreAllAsVariableMenu(this.sampler, {required this.liveItemsEnabled});

  final SnapshotClassSampler sampler;

  // TODO(https://github.com/flutter/devtools/issues/7905): this is a bug that
  // this is unused.
  final bool liveItemsEnabled;

  @override
  Widget build(BuildContext context) {
    final enabled = sampler.isEvalEnabled;
    const menuText = '存储当前应用中所有仍然存活的类实例';

    if (!enabled) {
      return const MenuItemButton(child: Text(menuText));
    }

    MenuItemButton item(
      String title, {
      required bool subclasses,
      required bool implementers,
    }) => MenuItemButton(
      onPressed: () async => await sampler.allLiveToConsole(
        includeImplementers: implementers,
        includeSubclasses: subclasses,
      ),
      child: Text(title),
    );

    return SubmenuButton(
      menuChildren: <Widget>[
        item('直接实例', implementers: false, subclasses: false),
        item('直接实例和子类实例', implementers: false, subclasses: false),
        item('直接实例和实现类实例', implementers: false, subclasses: false),
        item(
          '直接、子类以及实现类实例',
          implementers: false,
          subclasses: false,
        ),
      ],
      child: const Text(menuText),
    );
  }
}

class _StoreAsOneVariableMenu extends StatelessWidget {
  const _StoreAsOneVariableMenu(this.sampler, {required this.liveItemsEnabled});

  final SnapshotClassSampler sampler;
  final bool liveItemsEnabled;

  @override
  Widget build(BuildContext context) {
    final enabled = sampler.isEvalEnabled;
    const menuText = '将一个实例存为控制台变量';

    if (!enabled) {
      return const MenuItemButton(child: Text(menuText));
    }

    return SubmenuButton(
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: () => unawaited(
            sampler.oneStaticToConsole(
              sourceFeature: MemoryAreas.snapshotDiff.name,
            ),
          ),
          child: const Text('任意'),
        ),
        MenuItemButton(
          onPressed: liveItemsEnabled
              ? () => unawaited(
                  sampler.oneLiveStaticToConsole(
                    sourceFeature: MemoryAreas.snapshotDiff.name,
                  ),
                )
              : null,
          child: const Text('任意，未被垃圾回收'),
        ),
      ],
      child: const Text(menuText),
    );
  }
}
