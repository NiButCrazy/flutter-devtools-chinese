// Copyright 2021 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../shared/framework/screen.dart';
import '../../shared/ui/common_widgets.dart';

class ProviderScreen extends Screen {
  ProviderScreen() : super.fromMetaData(ScreenMetaData.provider);

  static final id = ScreenMetaData.provider.id;

  @override
  Widget buildScreenBody(BuildContext context) {
    return CenteredMessage(
      richMessage: [
        const TextSpan(
          text:
              'Provider 标签页面（未汉化）现已作为 DevTools 扩展提供，'
              '如果您想使用此工具，\n请将 ',
        ),
        TextSpan(
          text: 'package:provider',
          style: Theme.of(context).fixedFontStyle,
        ),
        const TextSpan(
          text: ' 依赖升级到最新版本，然后重新打开 DevTools',
        ),
      ],
    );
  }
}
