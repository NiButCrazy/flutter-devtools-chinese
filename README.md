<!--
Copyright 2025 The Flutter Authors
Use of this source code is governed by a BSD-style license that can be
found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.
-->
# Dart & Flutter DevTools

自用 Flutter DevTools, 大部分都汉化了, 和官方中文文档大差不差, 小部分文本为了方便理解换成了另一种表达

> 由于官方插件喜欢拿硬编码逻辑判断, 可能有未知BUG, 请自行测试

# 使用方法

首先先根据 tags 检出相应代码 `git checkout xxx`

1. 运行 `flutter pub get` 获取依赖
2. 运行 `flutter build web --release --no-tree-shake-icons --wasm` 生成构建后的代码
3. 替换 flutter-sdk 里的源文件(记得备份), 大抵是`..\caches\xxx\dart-sdk\bin\resources\devtools`

# 目前已汉化版本

- v2.51.1
- v2.54.1


调试部分去看官方文档吧

如果需要我帮你 build 并 release, 请提 issue
