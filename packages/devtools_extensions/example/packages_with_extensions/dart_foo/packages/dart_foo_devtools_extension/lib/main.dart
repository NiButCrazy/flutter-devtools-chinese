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
这是一个基本示例，展示一个由纯 Dart 包（"package:dart_foo"）提供的 DevTools 扩展示例。
若想了解更复杂、更有趣的 DevTools 扩展示例，请参考 "package:foo" 的示例。
''',
        ),
      ),
    );
  }
}
