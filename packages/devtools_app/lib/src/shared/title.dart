// Copyright 2021 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:flutter/foundation.dart';

import 'globals.dart';

void generateDevToolsTitle() {
  if (!serviceConnection.serviceManager.connectedAppInitialized) {
    _devToolsTitle.value = 'Flutter & Dart 开发者工具';
    return;
  }
  _devToolsTitle.value =
      serviceConnection.serviceManager.connectedApp!.isFlutterAppNow!
      ? 'Flutter 开发者工具'
      : 'Dart 开发者工具';
}

ValueListenable<String> get devToolsTitle => _devToolsTitle;

ValueNotifier<String> _devToolsTitle = ValueNotifier<String>('');
