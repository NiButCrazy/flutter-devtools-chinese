// Copyright 2023 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../shared/ui/common_widgets.dart';
import 'cpu_profiler_controller.dart';

class CpuProfilerDisabled extends StatelessWidget {
  const CpuProfilerDisabled(this.controller, {super.key});

  final CpuProfilerController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).regularTextStyle,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('CPU 分析器已禁用'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: controller.enableCpuProfiler,
                child: const Text('启用分析器'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyAppStartUpProfile extends StatelessWidget {
  const EmptyAppStartUpProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).regularTextStyle,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '没有可用的应用启动阶段采样数据',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: denseSpacing),
            Text(
              '要避免这种情况，请在启动应用后更早地打开 DevTools CPU 分析器',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyProfileView extends StatelessWidget {
  const EmptyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CenteredMessage(message: '未记录到任何 CPU 采样');
  }
}

class ProfileRecordingInstructions extends StatelessWidget {
  const ProfileRecordingInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).regularTextStyle,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('点击记录按钮 '),
                Icon(Icons.fiber_manual_record, size: defaultIconSize),
                Text(' 开始记录 CPU 采样'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('点击停止按钮 '),
                Icon(Icons.stop, size: defaultIconSize),
                Text(' 结束记录'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilerBusyStatus extends _Status {
  ProfilerBusyStatus({required CpuProfilerBusyStatus status})
    : assert(status != CpuProfilerBusyStatus.none),
      super(statusVerb: status.display);
}

class RecordingStatus extends _Status {
  const RecordingStatus() : super(statusVerb: '正在记录');
}

class _Status extends StatelessWidget {
  const _Status({required this.statusVerb});

  final String statusVerb;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$statusVerb CPU 采样',
            style: Theme.of(context).subtleTextStyle,
          ),
          const SizedBox(height: defaultSpacing),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
