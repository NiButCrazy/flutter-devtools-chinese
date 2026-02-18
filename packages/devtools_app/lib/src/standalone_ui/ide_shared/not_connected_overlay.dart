// Copyright 2025 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../shared/globals.dart';
import '../../shared/ui/common_widgets.dart';

/// An overlay to show when we are not connected to DTD based on the
/// [DTDConnectionState] classes.
class NotConnectedOverlay extends StatefulWidget {
  const NotConnectedOverlay(this.connectionState, {super.key});

  final DTDConnectionState connectionState;

  @override
  State<NotConnectedOverlay> createState() => _NotConnectedOverlayState();
}

class _NotConnectedOverlayState extends State<NotConnectedOverlay> {
  @override
  Widget build(BuildContext context) {
    final connectionState = widget.connectionState;
    final theme = Theme.of(context);

    final showSpinner = connectionState is! ConnectionFailedDTDState;
    final showReconnectButton = connectionState is ConnectionFailedDTDState;
    final stateLabel = switch (connectionState) {
      NotConnectedDTDState() => '等待连接中...',
      ConnectingDTDState() => '正在连接...',
      WaitingToRetryDTDState(seconds: final seconds) =>
        '$seconds 秒后重新连接...',
      ConnectionFailedDTDState() => '连接失败',
      // We should never present this widget when connected, but provide a label
      // for debugging if it happens.
      ConnectedDTDState() => '已连接',
    };

    return DevToolsOverlay(
      fullScreen: true,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSpinner) ...const [
            CircularProgressIndicator(),
            SizedBox(height: defaultSpacing),
          ],
          Text(stateLabel, style: theme.textTheme.headlineMedium),
          if (showReconnectButton)
            ElevatedButton(
              onPressed: () => dtdManager.reconnect(),
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }
}
