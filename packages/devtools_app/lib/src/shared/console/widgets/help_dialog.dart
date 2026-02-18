// Copyright 2023 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../analytics/constants.dart' as gac;
import '../../ui/common_widgets.dart';

const _documentationTopic = gac.console;

class ConsoleHelpDialog extends StatelessWidget {
  const ConsoleHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.regularTextStyle;
    return DevToolsDialog(
      title: const DialogTitleText('控制台帮助'),
      includeDivider: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RichText(
            text: TextSpan(
              style: textStyle,
              children: [
                const TextSpan(
                  text: r'''
使用调试控制台可以：

1. 查看应用程序的标准输出（stdout）
2. 在调试模式下，对暂停或正在运行的应用求值表达式
3. 分析对象的入站和出站引用，包括来自内存堆快照中已被丢弃的对象
4. 您还可以使用 $0、$1 … $5 将之前求值过的对象分配给变量
    例如: ''',
                ),
                TextSpan(text: r'var x = $0', style: theme.fixedFontStyle),
              ],
            ),
          ),
          MoreInfoLink(
            // TODO(polina-c): create content and change url.
            url: 'https://docs.flutter.cn/tools/devtools/console',
            gaScreenName: gac.console,
            gaSelectedItemDescription: gac.topicDocumentationLink(
              _documentationTopic,
            ),
          ),
        ],
      ),
      actions: const [DialogCloseButton()],
    );
  }
}

class ConsoleHelpLink extends StatelessWidget {
  const ConsoleHelpLink({super.key});

  @override
  Widget build(BuildContext context) {
    return ToolbarAction(
      icon: Icons.help_outline,
      size: defaultIconSize,
      tooltip: '控制台帮助',
      onPressed: () {
        unawaited(
          showDialog(
            context: context,
            builder: (context) => const ConsoleHelpDialog(),
          ),
        );
      },
      gaScreen: gac.console,
      gaSelection: gac.topicDocumentationButton(_documentationTopic),
    );
  }
}
