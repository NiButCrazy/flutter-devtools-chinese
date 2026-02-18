// Copyright 2018 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:devtools_app_shared/service_extensions.dart' as extensions;
import 'package:flutter/material.dart';

import '../shared/analytics/constants.dart' as gac;

/// Interface that service extension objects used in DevTools must implement.
abstract class ServiceExtensionInterface {
  String get title;

  String? get iconAsset;

  IconData? get iconData;

  List<String> get displayValues;

  /// Analytics screen (screen name where item lives).
  String? get gaScreenName;

  String? get gaItem;

  String get tooltip;

  String? get description;

  String? get documentationUrl;

  String? get gaDocsItem;

  String get gaItemTooltipLink;

  String? get shortTitle;
}

/// A subclass of [extensions.ToggleableServiceExtension] that includes metadata
/// for displaying and interacting with a toggleable service extension in the
/// DevTools UI.
class ToggleableServiceExtensionDescription<T extends Object>
    extends extensions.ToggleableServiceExtension
    implements ServiceExtensionInterface {
  ToggleableServiceExtensionDescription._({
    required super.extension,
    required super.enabledValue,
    required super.disabledValue,
    required this.title,
    required this.gaScreenName,
    required this.gaItem,
    required this.tooltip,
    super.shouldCallOnAllIsolates = false,
    super.inverted = false,
    this.description,
    this.documentationUrl,
    this.gaDocsItem,
    this.iconAsset,
    this.iconData,
    this.shortTitle,
  }) : displayValues = [
         enabledValue,
         disabledValue,
       ].map((v) => v.toString()).toList(),
       assert((iconAsset == null) != (iconData == null)),
       assert((documentationUrl == null) == (gaDocsItem == null));

  factory ToggleableServiceExtensionDescription.from(
    extensions.ToggleableServiceExtension<T> extension, {
    required String title,
    required String? gaScreenName,
    required String? gaItem,
    required String tooltip,
    String? description,
    String? documentationUrl,
    String? gaDocsItem,
    String? iconAsset,
    IconData? iconData,
    String? shortTitle,
  }) {
    return ToggleableServiceExtensionDescription._(
      extension: extension.extension,
      enabledValue: extension.enabledValue,
      disabledValue: extension.disabledValue,
      shouldCallOnAllIsolates: extension.shouldCallOnAllIsolates,
      inverted: extension.inverted,
      title: title,
      gaScreenName: gaScreenName,
      gaItem: gaItem,
      tooltip: tooltip,
      description: description,
      documentationUrl: documentationUrl,
      gaDocsItem: gaDocsItem,
      iconAsset: iconAsset,
      iconData: iconData,
      shortTitle: shortTitle,
    );
  }

  @override
  final String title;

  @override
  final String? iconAsset;

  @override
  final IconData? iconData;

  @override
  final List<String> displayValues;

  @override
  final String? gaScreenName;

  @override
  final String? gaItem;

  @override
  final String tooltip;

  @override
  final String? description;

  @override
  final String? documentationUrl;

  @override
  final String? gaDocsItem;

  @override
  final String? shortTitle;

  @override
  String get gaItemTooltipLink => '${gaItem}TooltipLink';
}

/// A subclass of [extensions.ServiceExtension] that includes metadata for
/// displaying and interacting with a service extension in the DevTools UI.
class ServiceExtensionDescription<T> extends extensions.ServiceExtension<T>
    implements ServiceExtensionInterface {
  ServiceExtensionDescription._({
    required super.extension,
    required super.values,
    super.shouldCallOnAllIsolates = false,
    this.iconAsset,
    this.iconData,
    List<String>? displayValues,
    required this.title,
    required this.gaScreenName,
    required this.gaItem,
    required this.tooltip,
    this.description,
    this.documentationUrl,
    this.shortTitle,
    this.gaDocsItem,
  }) : displayValues =
           displayValues ?? values.map((v) => v.toString()).toList(),
       assert((iconAsset == null) != (iconData == null)),
       assert((documentationUrl == null) == (gaDocsItem == null));

  factory ServiceExtensionDescription.from(
    extensions.ServiceExtension<T> extension, {
    required String title,
    required String? gaScreenName,
    required String? gaItem,
    required String tooltip,
    String? description,
    String? documentationUrl,
    String? gaDocsItem,
    String? iconAsset,
    IconData? iconData,
    String? shortTitle,
    List<String>? displayValues,
  }) {
    return ServiceExtensionDescription._(
      extension: extension.extension,
      values: extension.values,
      shouldCallOnAllIsolates: extension.shouldCallOnAllIsolates,
      title: title,
      gaScreenName: gaScreenName,
      gaItem: gaItem,
      tooltip: tooltip,
      description: description,
      documentationUrl: documentationUrl,
      gaDocsItem: gaDocsItem,
      iconAsset: iconAsset,
      iconData: iconData,
      shortTitle: shortTitle,
      displayValues: displayValues,
    );
  }

  @override
  final String title;

  @override
  final String? iconAsset;

  @override
  final IconData? iconData;

  @override
  final List<String> displayValues;

  @override
  final String? gaScreenName;

  @override
  final String? gaItem;

  @override
  final String tooltip;

  @override
  final String? description;

  @override
  final String? documentationUrl;

  @override
  final String? gaDocsItem;

  @override
  final String? shortTitle;

  @override
  String get gaItemTooltipLink => '${gaItem}TooltipLink';
}

final debugAllowBanner = ToggleableServiceExtensionDescription<bool>.from(
  extensions.debugAllowBanner,
  title: '调试横幅',
  iconAsset: 'icons/debug_banner@2x.png',
  gaScreenName: gac.inspector,
  gaItem: gac.debugBanner,
  tooltip: '切换调试横幅',
);

final invertOversizedImages = ToggleableServiceExtensionDescription<bool>.from(
  extensions.invertOversizedImages,
  title: '高亮尺寸过大图片',
  iconAsset: 'icons/images-white.png',
  gaScreenName: gac.inspector,
  gaItem: gac.highlightOversizedImages,
  tooltip:
      '通过反转颜色并翻转图像来高亮显示占用过多内存的图像',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/inspector#highlight-oversized-images',
  gaDocsItem: gac.highlightOversizedImagesDocs,
);

final debugPaint = ToggleableServiceExtensionDescription<bool>.from(
  extensions.debugPaint,
  title: '显示引导线',
  iconAsset: 'icons/guidelines-white.png',
  gaScreenName: gac.inspector,
  gaItem: gac.debugPaint,
  tooltip: '该功能会在您的应用顶层绘制引导线，展示绘制区域、对齐、间距、滚动视图、裁剪和空位填充',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/inspector#show-guidelines',
  gaDocsItem: gac.debugPaintDocs,
);

final debugPaintBaselines = ToggleableServiceExtensionDescription<bool>.from(
  extensions.debugPaintBaselines,
  title: '显示基线',
  iconAsset: 'icons/baselines-white.png',
  gaScreenName: gac.inspector,
  gaItem: gac.paintBaseline,
  tooltip:
      '该选项会显示所有的基线，基线是水平的用来定位文字的线，在检查文字是否垂直对齐时会非常有用',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/inspector#show-baselines',
  gaDocsItem: gac.paintBaselineDocs,
);

final performanceOverlay = ToggleableServiceExtensionDescription<bool>.from(
  extensions.performanceOverlay,
  title: '观察性能图层',
  iconAsset: 'icons/performance-white.png',
  gaScreenName: gac.performance,
  gaItem: gac.PerformanceEvents.performanceOverlay.name,
  tooltip: '在您的应用上叠加性能图表。',
  documentationUrl: 'https://docs.flutter.cn/perf/ui-performance#performance-overlay',
  gaDocsItem: gac.PerformanceDocs.performanceOverlayDocs.name,
);

final profileWidgetBuilds = ToggleableServiceExtensionDescription<bool>.from(
  extensions.profileWidgetBuilds,
  title: '追踪组件创建',
  iconAsset: 'icons/trackwidget-white.png',
  gaScreenName: gac.performance,
  gaItem: gac.PerformanceEvents.trackRebuilds.name,
  description: '为每个创建的组件添加一个时间线事件',
  tooltip: '',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/performance#track-widget-builds',
  gaDocsItem: gac.PerformanceDocs.trackWidgetBuildsDocs.name,
);

final profileUserWidgetBuilds = ToggleableServiceExtensionDescription<bool>.from(
  extensions.profileUserWidgetBuilds,
  title: '追踪用户代码组件创建',
  iconAsset: 'icons/trackwidget-white.png',
  gaScreenName: gac.performance,
  gaItem: gac.PerformanceEvents.trackUserCreatedWidgetBuilds.name,
  description:
      '为用户代码中创建的每个组件添加一个时间线事件',
  tooltip: '',
);

final profileRenderObjectPaints =
    ToggleableServiceExtensionDescription<bool>.from(
      extensions.profileRenderObjectPaints,
      title: '追踪绘制',
      iconData: Icons.format_paint,
      gaScreenName: gac.performance,
      gaItem: gac.PerformanceEvents.trackPaints.name,
      description:
          '为每个绘制的 RenderObject 添加一个时间线事件',
      tooltip: '',
      documentationUrl:
          'https://docs.flutter.cn/tools/devtools/performance#track-paints',
      gaDocsItem: gac.PerformanceDocs.trackPaintsDocs.name,
    );

final profileRenderObjectLayouts =
    ToggleableServiceExtensionDescription<bool>.from(
      extensions.profileRenderObjectLayouts,
      title: '追踪布局',
      iconData: Icons.auto_awesome_mosaic,
      gaScreenName: gac.performance,
      gaItem: gac.PerformanceEvents.trackLayouts.name,
      description:
          '为每个 RenderObject 布局构建添加一个时间轴事件',
      tooltip: '',
      documentationUrl:
          'https://docs.flutter.cn/tools/devtools/performance#track-layouts',
      gaDocsItem: gac.PerformanceDocs.trackLayoutsDocs.name,
    );

final repaintRainbow = ToggleableServiceExtensionDescription<bool>.from(
  extensions.repaintRainbow,
  title: '高亮重绘制内容',
  iconAsset: 'icons/repaints-white.png',
  gaScreenName: gac.inspector,
  gaItem: gac.repaintRainbow,
  tooltip:
      '该选项会为所有的 RenderBox 绘制一层边框，在它们重新绘制时改变颜色',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/inspector#highlight-repaints',
  gaDocsItem: gac.repaintRainbowDocs,
);

final slowAnimations = ToggleableServiceExtensionDescription<num>.from(
  extensions.slowAnimations,
  title: '慢速动画',
  iconAsset: 'icons/slow-white.png',
  gaScreenName: gac.inspector,
  gaItem: gac.slowAnimation,
  tooltip: '启用时，动画将以约五分之一的原有速度运行，方便对视觉效果进行检查',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/inspector#slow-animations',
  gaDocsItem: gac.slowAnimationDocs,
);

final togglePlatformMode = ServiceExtensionDescription<String>.from(
  extensions.togglePlatformMode,
  title: '覆盖目标平台',
  iconAsset: 'icons/phone@2x.png',
  displayValues: [
    '平台: iOS',
    '平台: Android',
    '平台: Fuchsia',
    '平台: MacOS',
    '平台: Linux',
  ],
  gaScreenName: gac.inspector,
  gaItem: gac.togglePlatform,
  tooltip: '覆盖目标平台',
);

final disableClipLayers = ToggleableServiceExtensionDescription<bool>.from(
  extensions.disableClipLayers,
  title: '渲染裁剪的图层',
  iconData: Icons.cut_outlined,
  gaScreenName: gac.performance,
  gaItem: gac.PerformanceEvents.disableClipLayers.name,
  description: '在绘制过程中渲染所有裁剪效果',
  tooltip: '''禁用该选项来检查已使用的裁剪图层是否影响了性能；如果禁用后性能有显著提升，请尝试减少您的应用中裁剪效果的使用''',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/performance#more-debugging-options',
  gaDocsItem: gac.PerformanceDocs.disableClipLayersDocs.name,
);

final disableOpacityLayers = ToggleableServiceExtensionDescription<bool>.from(
  extensions.disableOpacityLayers,
  title: '渲染透明度图层',
  iconData: Icons.opacity,
  gaScreenName: gac.performance,
  gaItem: gac.PerformanceEvents.disableOpacityLayers.name,
  description: '在绘制过程中渲染所有透明度效果',
  tooltip: '''禁用该选项来检查已使用的透明度图层是否影响了性能；如果禁用后性能有显著提升，请尝试减少您的应用中透明度效果的使用''',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/performance#more-debugging-options',
  gaDocsItem: gac.PerformanceDocs.disableOpacityLayersDocs.name,
);

final disablePhysicalShapeLayers = ToggleableServiceExtensionDescription<bool>.from(
  extensions.disablePhysicalShapeLayers,
  title: '渲染物理形状图层',
  iconData: Icons.format_shapes,
  gaScreenName: gac.performance,
  gaItem: gac.PerformanceEvents.disablePhysicalShapeLayers.name,
  description: '在绘制过程中渲染所有物理效果.',
  tooltip: '''禁用该选项来检查已使用的物理形状图层是否影响了性能，例如阴影和背景特效；如果禁用后性能有显著提升，请尝试减少您的应用中物理效果的使用''',
  documentationUrl:
      'https://docs.flutter.cn/tools/devtools/performance#more-debugging-options',
  gaDocsItem: gac.PerformanceDocs.disablePhysicalShapeLayersDocs.name,
);

final httpEnableTimelineLogging =
    ToggleableServiceExtensionDescription<bool>.from(
      extensions.httpEnableTimelineLogging,
      title: '是否启用 HTTP 时间线日志记录',
      iconData: Icons.http,
      gaScreenName: null,
      gaItem: null,
      tooltip: '切换 HTTP 时间线日志记录是否启用',
    );

/// The icon used for all "Select widget mode" buttons, both in DevTools and in
/// the Flutter framework.
///
/// This is a generic unicode icon which lets us have one consistent icon across
/// Material and Cupertino-styled apps.
const selectWidgetModeIcon = IconData(0x1F74A);

// Legacy extension to show the inspector and enable inspector select mode.
final toggleOnDeviceWidgetInspector =
    ToggleableServiceExtensionDescription<bool>.from(
      extensions.toggleOnDeviceWidgetInspector,
      // Technically this enables the on-device widget inspector but for older
      // versions of package:flutter it makes sense to describe this extension as
      // toggling widget select mode as it is the only way to toggle that mode.
      title: '组件选择模式',
      shortTitle: '选择',
      iconData: selectWidgetModeIcon,
      gaScreenName: gac.inspector,
      gaItem: gac.showOnDeviceInspector,
      tooltip: '切换是否选择组件的模式',
    );

// TODO(kenz): remove this if it is not needed. According to the comments,
// [toggleOnDeviceWidgetInspector] should be the legacy extension, but that is
// the only extension available, and [toggleSelectWidgetMode] is not.
/// Toggle whether interacting with the device selects widgets or triggers
/// normal interactions.
final toggleSelectWidgetMode = ToggleableServiceExtensionDescription<bool>.from(
  extensions.toggleSelectWidgetMode,
  title: '组件选择模式',
  iconData: selectWidgetModeIcon,
  gaScreenName: gac.inspector,
  gaItem: gac.selectWidgetMode,
  tooltip: '切换是否启用选择组件的模式',
);

// TODO(kenz): remove this if it is not needed. According to the comments,
// [toggleOnDeviceWidgetInspector] should be the legacy extension, but that is
// the only extension available, and [toggleSelectWidgetMode] is not. And in
// DevTools code, [enableOnDeviceInspector] is only called when
// [toggleSelectWidgetMode] is available.
/// Toggle whether the inspector on-device overlay is enabled.
///
/// When available, the inspector overlay can be enabled at any time as it will
/// not interfere with user interaction with the app unless inspector select
/// mode is triggered.
final enableOnDeviceInspector =
    ToggleableServiceExtensionDescription<bool>.from(
      extensions.enableOnDeviceInspector,
      title: '启用设备端检查器',
      iconAsset: 'icons/general/locate@2x.png',
      gaScreenName: gac.inspector,
      gaItem: gac.enableOnDeviceInspector,
      tooltip: '切换设备端检查器是否启用',
    );

final structuredErrors = ToggleableServiceExtensionDescription<bool>.from(
  extensions.structuredErrors,
  title: '显示结构化错误',
  iconAsset: 'icons/perf/RedExcl@2x.png',
  gaScreenName: gac.logging,
  gaItem: gac.structuredErrors,
  tooltip: '切换是否显示来自 Flutter 框架问题的结构化错误',
);

final countWidgetBuilds = ToggleableServiceExtensionDescription<bool>.from(
  extensions.countWidgetBuilds,
  title: '统计组件创建次数',
  iconAsset: 'icons/inspector/diagram@2x.png',
  gaScreenName: gac.performance,
  gaItem: gac.PerformanceEvents.countWidgetBuilds.nameOverride!,
  description: '为每一 Flutter 帧渲染统计组件的创建次数',
  tooltip: '''启用此选项后，您将能够使用帧分析工具查看每个 Flutter 帧中创建的组件，或使用重建统计工具查看这些计数的汇总信息''',
  // TODO(https://github.com/flutter/website/issues/10666): link docs
);

final profilePlatformChannels = ToggleableServiceExtensionDescription<bool>.from(
  extensions.profilePlatformChannels,
  title: '跟踪平台渠道',
  iconAsset: 'icons/trackwidget-white.png',
  gaScreenName: gac.performance,
  gaItem: gac.PerformanceEvents.profilePlatformChannels.name,
  description:
      '为平台通道消息在时间轴中添加事件（对使用插件的应用特别有帮助），并定期将平台通道的统计数据输出到控制台',
  tooltip: '',
  documentationUrl: 'https://docs.flutter.cn/platform-integration/platform-channels',
  gaDocsItem: gac.PerformanceDocs.platformChannelsDocs.name,
);
