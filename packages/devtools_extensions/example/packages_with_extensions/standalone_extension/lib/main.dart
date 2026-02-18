// Copyright 2024 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DartFooDevToolsExtension());
}

class DartFooDevToolsExtension extends StatelessWidget {
  const DartFooDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: Center(
        child: Text(
          '''
这是一个用于展示独立扩展（standalone extension）的基础示例。
独立扩展并不是某个现有 package 的配套工具，而是可用于任意 Dart / Flutter 项目的开发工具。

本示例还展示了一个不依赖正在运行的应用程序即可使用的扩展示例。
“app_that_uses_foo” 项目会将此示例作为 dev_dependency 引入。

如果你想了解更有趣、功能更多的 DevTools 扩展示例，
可以查看 “package:foo” 提供的扩展示例。
''',
        ),
      ),
    );
  }
}
