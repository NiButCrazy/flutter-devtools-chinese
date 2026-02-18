// Copyright 2020 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';
import 'dart:core';

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart' hide Error;

import '../shared/globals.dart';
import 'vm_service_wrapper.dart';

class TimelineStreamManager with DisposerMixin {
  static const dartTimelineStream = 'Dart';
  static const embedderTimelineStream = 'Embedder';
  static const gcTimelineStream = 'GC';
  static const apiTimelineStream = 'API';
  static const compilerTimelineStream = 'Compiler';
  static const compilerVerboseTimelineStream = 'CompilerVerbose';
  static const debuggerTimelineStream = 'Debugger';
  static const isolateTimelineStream = 'Isolate';
  static const vmTimelineStream = 'VM';

  final _advancedStreams = <String>{
    apiTimelineStream,
    compilerTimelineStream,
    compilerVerboseTimelineStream,
    debuggerTimelineStream,
    isolateTimelineStream,
    vmTimelineStream,
  };

  final _streamDescriptions = <String, String>{
    dartTimelineStream:
    '由 dart:developer 的 Timeline API 发出的事件（包括 Flutter 框架事件）',
    embedderTimelineStream:
        '额外的平台事件（通常由 Flutter 引擎发出）',
    gcTimelineStream: '垃圾回收',
    apiTimelineStream: '对 VM 嵌入式 API 的调用',
    compilerTimelineStream:
        '编译器阶段（代码加载、编译、优化等）',
    compilerVerboseTimelineStream: '更详细的编译器阶段',
    debuggerTimelineStream: '调试器暂停事件',
    isolateTimelineStream:
        'Isolate 事件（启动、关闭、加载快照等）',
    vmTimelineStream:
        'Dart VM 事件（启动、关闭、加载快照等）',
  };

  VmServiceWrapper? get service => _service;
  VmServiceWrapper? _service;

  final _streams = <String, TimelineStream>{};

  List<TimelineStream> get basicStreams =>
      _streamsWhere((stream) => !stream.advanced);

  List<TimelineStream> get advancedStreams =>
      _streamsWhere((stream) => stream.advanced);

  List<TimelineStream> get recordedStreams =>
      _streamsWhere((stream) => stream.recorded.value);

  List<TimelineStream> _streamsWhere(bool Function(TimelineStream) condition) {
    return _streams.values.where(condition).toList();
  }

  /// Initializes stream values from the vm service as a source of truth.
  Future<void> _initStreams() async {
    final timelineFlags = await service!.getVMTimelineFlags();
    _streams
      ..clear()
      ..addEntries([
        for (final streamName in timelineFlags.availableStreams ?? <String>[])
          MapEntry(
            streamName,
            TimelineStream(
              name: streamName,
              description: _streamDescriptions[streamName] ?? '',
              advanced: _advancedStreams.contains(streamName),
              recorded:
                  timelineFlags.recordedStreams?.contains(streamName) ?? false,
            ),
          ),
      ]);
  }

  /// Handles events from the VM service 'TimelineEvent' stream to track updates
  /// for recorded timeline streams.
  ///
  /// This method is responsible for updating the value of
  /// [TimelineStream.recorded] for each stream to match the value on the VM.
  @visibleForTesting
  void handleTimelineEvent(Event event) {
    if (event.kind == EventKind.kTimelineStreamSubscriptionsUpdate) {
      final newRecordedStreams = event.updatedStreams ?? <String>[];
      for (final stream in _streams.values) {
        stream._toggle(newRecordedStreams.contains(stream.name));
        newRecordedStreams.remove(stream.name);
      }
      if (newRecordedStreams.isNotEmpty) {
        // A new stream became available that we were not aware of.
        for (final unknownStream in newRecordedStreams) {
          _streams[unknownStream] = TimelineStream(
            name: unknownStream,
            description: _streamDescriptions[unknownStream] ?? '',
            // If we don't know about this stream, assume it is advanced.
            advanced: true,
            recorded: true,
          );
        }
      }
    }
  }

  void vmServiceOpened(VmServiceWrapper service, ConnectedApp connectedApp) {
    cancelStreamSubscriptions();
    _service = service;

    // Listen for timeline events immediately, but wait until [connectedApp]
    // has been initialized to initialize timeline stream values.
    autoDisposeStreamSubscription(
      service.onTimelineEvent.listen(handleTimelineEvent),
    );
    unawaited(
      connectedApp.initialized.future.then((_) async {
        // The timeline is not supported for web applications.
        if (!connectedApp.isDartWebAppNow!) {
          await _initStreams();
        }
      }),
    );
  }

  void vmServiceClosed() {
    _streams.clear();
    _service = null;
  }

  Future<void> setDefaultTimelineStreams() async {
    await serviceConnection.serviceManager.service!.setVMTimelineFlags([
      dartTimelineStream,
      embedderTimelineStream,
      gcTimelineStream,
    ]);
  }

  /// Sends an update to the VM service that the new recorded value for [stream]
  /// should match [value].
  Future<void> updateTimelineStream(TimelineStream stream, bool value) async {
    final recordedStreamNames = _streams.keys
        .where((streamName) => _streams[streamName]!.recorded.value)
        .toList();
    final alreadyBeingRecorded = recordedStreamNames.contains(stream.name);
    if (alreadyBeingRecorded && !value) {
      recordedStreamNames.remove(stream.name);
    } else if (!alreadyBeingRecorded && value) {
      recordedStreamNames.add(stream.name);
    }
    await serviceConnection.serviceManager.service!.setVMTimelineFlags(
      recordedStreamNames,
    );
  }
}

class TimelineStream {
  TimelineStream({
    required this.name,
    required this.description,
    required this.advanced,
    bool recorded = false,
  }) : _recorded = ValueNotifier<bool>(recorded);

  final String name;

  final String description;

  final bool advanced;

  ValueListenable<bool> get recorded => _recorded;
  final ValueNotifier<bool> _recorded;

  void _toggle(bool value) {
    _recorded.value = value;
  }
}
