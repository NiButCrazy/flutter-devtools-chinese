// Copyright 2023 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../../shared/ui/colors.dart';
import '../../shared/ui/common_widgets.dart';
import '../../shared/utils/utils.dart';
import 'deep_link_list_view.dart';
import 'deep_links_controller.dart';
import 'deep_links_model.dart';
import 'deep_links_services.dart';

class ValidationDetailView extends StatelessWidget {
  const ValidationDetailView({
    super.key,
    required this.viewType,
    required this.controller,
  });

  final TableViewType viewType;
  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      // TODO(hangyujin): Set `minTileHeight` when it is available for devtool.
      // related PR: https://github.com/flutter/flutter/pull/145244
      data: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 0,
        contentPadding: EdgeInsets.zero,
      ),
      child: ListView(
        children: [
          ValidationDetailHeader(viewType: viewType, controller: controller),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: extraLargeSpacing,
              vertical: defaultSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
'此工具可帮助你诊断应用中 App Links 的相关问题。'
'网页检查用于检测你网站上的关联文件。应用检查则用于检测 manifest 和 info.plist 文件中的 intent filters、路由问题、URL 格式等内容。',
                  style: Theme.of(context).subtleTextStyle,
                ),
                if (viewType == TableViewType.domainView ||
                    viewType == TableViewType.singleUrlView)
                  _DomainCheckTable(controller: controller),
                if (viewType == TableViewType.pathView ||
                    viewType == TableViewType.singleUrlView)
                  _PathCheckTable(controller: controller),
                if (viewType == TableViewType.domainView)
                  _CrossCheckTable(controller: controller),
                const SizedBox(height: extraLargeSpacing),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton(
                    onPressed: () async {
                      await controller.loadLinksAndValidate();
                      controller.autoSelectLink(viewType);
                    },
                    child: const Text('重新全部检查'),
                  ),
                ),
                if (viewType == TableViewType.domainView)
                  _DomainAssociatedLinksPanel(controller: controller),
                const SizedBox(height: largeSpacing),
                const _ViewDeveloperGuide(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ValidationDetailHeader extends StatelessWidget {
  const ValidationDetailHeader({
    super.key,
    required this.viewType,
    required this.controller,
  });

  final TableViewType viewType;
  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    return OutlineDecoration(
      showLeft: false,
      showRight: false,
      child: Container(
        height: actionWidgetSize,
        padding: const EdgeInsets.symmetric(horizontal: defaultSpacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              viewType == TableViewType.domainView
                  ? '选中域名的校验详情'
                  : '选中深度链接的校验详情',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              onPressed: () =>
                  controller.updateDisplayOptions(showSplitScreen: false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainCheckTable extends StatelessWidget {
  const _DomainCheckTable({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final linkData = controller.selectedLink.value!;
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: controller.localFingerprint,
      builder: (context, localFingerprint, _) {
        final fingerprintExists =
            controller.googlePlayFingerprintsAvailability.value ||
            localFingerprint != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: intermediateSpacing),
            Text('网页检查', style: theme.textTheme.titleMedium),
            const SizedBox(height: denseSpacing),
            const _CheckTableHeader(),
            if (linkData.os.contains(PlatformOS.android))
              _CheckExpansionTile(
                os: PlatformOS.android,
                initiallyExpanded: !fingerprintExists,
                checkName: '数字资产链接文件',
                status: _CheckStatusText(
                  hasError:
                      !fingerprintExists ||
                      linkData.domainErrors.any((e) => e is AndroidDomainError),
                ),
                children: <Widget>[
                  _Fingerprint(controller: controller),
                  // The following checks are only displayed if a fingerprint exists.
                  if (fingerprintExists) ...[
                    _AssetLinksJsonFileIssues(controller: controller),
                    _HostingIssues(controller: controller),
                  ],
                ],
              ),
            if (linkData.os.contains(PlatformOS.ios))
              _CheckExpansionTile(
                os: PlatformOS.ios,
                checkName: 'Apple-App-Site-Association 文件',
                status: _CheckStatusText(
                  hasError: linkData.domainErrors.any(
                    (e) => e is IosDomainError,
                  ),
                ),
                children: <Widget>[
                  for (final error
                      in linkData.domainErrors.whereType<IosDomainError>())
                    _IssuesBorderWrap(
                      children: error == IosDomainError.existence
                          ? [
                              _FailureDetails(
                                errors: [error],
                                oneFixGuideForAll:
                                    '要修复此问题，请在以下位置添加 Apple-App-Site-Association 文件： '
                                  'https://${controller.selectedLink.value!.domain}/.well-known/apple-app-site-association',
                              ),
                              const SizedBox(height: denseSpacing),
                              _CodeCard(
                                content:
                                    '''{
  "applinks": {
    "details": [
      {
        "appIDs": [
          "${controller.teamId}.${controller.bundleId}"
        ],
        "components": [
          {
            "/": "*"
          }
        ]
      }
    ]
  }
}''',
                              ),
                            ]
                          : [
                              _FailureDetails(
                                errors: [error, ...error.subcheckErrors],
                              ),
                            ],
                    ),
                ],
              ),
            const SizedBox(height: intermediateSpacing),
          ],
        );
      },
    );
  }
}

/// There is a general fix for the asset links json file issues:
/// Update it with the generated asset link file.
class _AssetLinksJsonFileIssues extends StatelessWidget {
  const _AssetLinksJsonFileIssues({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final errors = controller.selectedLink.value!.domainErrors
        .where((error) => domainAssetLinksJsonFileErrors.contains(error))
        .toList();
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.leading,
      title: _VerifiedOrErrorText(
        '数字资产链接 JSON 文件相关问题',
        isError: errors.isNotEmpty,
      ),
      children: [
        if (errors.isNotEmpty)
          _IssuesBorderWrap(
            children: [
              _FailureDetails(
                errors: errors,
                oneFixGuideForAll:
                    '要修复以上问题，请复制下方推荐的数字资产链接 JSON 文件，'
                  '并将其发布到所有失败的网站域名的以下位置： '
                  'https://${controller.selectedLink.value!.domain}/.well-known/assetlinks.json。',
              ),
              const SizedBox(height: denseSpacing),
              _GenerateAssetLinksPanel(controller: controller),
            ],
          ),
      ],
    );
  }
}

/// Hosting issue cannot be fixed by generated asset link file.
/// There is a fix guide for each hosting issue.
class _HostingIssues extends StatelessWidget {
  const _HostingIssues({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final errors = controller.selectedLink.value!.domainErrors
        .where((error) => domainAndroidHostingErrors.contains(error))
        .toList();
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.leading,
      title: _VerifiedOrErrorText(
        '托管相关问题',
        isError: errors.isNotEmpty,
      ),
      children: [
        for (final error in errors)
          _IssuesBorderWrap(
            children: [
              _FailureDetails(errors: [error]),
            ],
          ),
      ],
    );
  }
}

class _Fingerprint extends StatelessWidget {
  const _Fingerprint({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPdcFingerprint =
        controller.googlePlayFingerprintsAvailability.value;
    final haslocalFingerprint = controller.localFingerprint.value != null;
    final isError = !hasPdcFingerprint && !haslocalFingerprint;
    late String title;
    if (hasPdcFingerprint && haslocalFingerprint) {
      title = '检测到 PDC 指纹和本地指纹';
    }
    if (hasPdcFingerprint && !haslocalFingerprint) {
      title = '检测到 PDC 指纹，如有需要请输入本地指纹';
    }
    if (!hasPdcFingerprint && haslocalFingerprint) {
      title = '检测到本地指纹';
    }
    if (isError) {
      title = '由于未检测到指纹，无法继续检查';
    }

    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.leading,
      initiallyExpanded: isError,
      title: _VerifiedOrErrorText(title, isError: isError),
      children: [
        _IssuesBorderWrap(
          children: [
            if (hasPdcFingerprint && !haslocalFingerprint) ...[
              Text(
                '已检测到你的 PDC 指纹。如果你有本地指纹，可以在下方输入',
                style: theme.subtleTextStyle,
              ),
              const SizedBox(height: denseSpacing),
            ],
            if (isError) ...[
              const Text('问题：未检测到本地或 PDC 指纹'),
              const SizedBox(height: denseSpacing),
              const Text('修复指南：'),
              const SizedBox(height: denseSpacing),
              Text(
                '要修复此问题，请在 Play Developer Console 上发布你的应用以获取指纹。'
                '如果暂时不准备发布应用，可以在下方输入本地指纹继续进行 Android 域名检查。',
                style: theme.subtleTextStyle,
              ),
              const SizedBox(height: denseSpacing),
            ],
            // User can add local fingerprint no matter PDC fingerprint is detected or not.
            _LocalFingerprint(controller: controller),
          ],
        ),
      ],
    );
  }
}

class _LocalFingerprint extends StatelessWidget {
  const _LocalFingerprint({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('本地指纹'),
        const SizedBox(height: intermediateSpacing),
        controller.localFingerprint.value == null
            ? TextField(
                decoration: const InputDecoration(
                  labelText: '请输入你的本地指纹',
                  hintText:
                      '例如：A1:B2:C3:D4:A1:B2:C3:D4:A1:B2:C3:D4:A1:B2:C3:D4:A1:B2:C3:D4:A1:B2:C3:D4:A1:B2:C3:D4:A1:B2:C3:D4',
                  filled: true,
                ),
                onSubmitted: (fingerprint) async {
                  final validFingerprintAdded = controller.addLocalFingerprint(
                    fingerprint,
                  );

                  if (!validFingerprintAdded) {
                    await showDialog(
                      context: context,
                      builder: (_) {
                        return const DevToolsDialog(
                          title: Text('这不是一个有效的指纹'),
                          content: Text(
                            '有效的指纹应由 32 组用冒号分隔的十六进制数字组成，'
                            '格式和编码应与 assetlinks.json 文件中的一致。',
                          ),
                          actions: [DialogCloseButton()],
                        );
                      },
                    );
                  }
                },
              )
            : _CodeCard(
                content: controller.localFingerprint.value,
                hasCopyAction: false,
              ),
      ],
    );
  }
}


class _ViewDeveloperGuide extends StatelessWidget {
  const _ViewDeveloperGuide();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DevToolsButton(
        onPressed: () {
          unawaited(
            launchUrlWithErrorHandling(
              'https://developer.android.com/training/app-links/verify-android-applinks',
            ),
          );
        },
        label: '查看开发者指南',
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({this.content, this.hasCopyAction = true});

  final String? content;
  final bool hasCopyAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.alternatingBackgroundColor1,
      elevation: 0.0,
      child: Padding(
        padding: const EdgeInsets.all(denseSpacing),
        child: content != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(child: SelectionArea(child: Text(content!))),
                  if (hasCopyAction)
                    CopyToClipboardControl(dataProvider: () => content),
                ],
              )
            : const CenteredCircularProgressIndicator(),
      ),
    );
  }
}

class _GenerateAssetLinksPanel extends StatelessWidget {
  const _GenerateAssetLinksPanel({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: controller.generatedAssetLinksForSelectedLink,
      builder: (_, GenerateAssetLinksResult? generatedAssetLinks, _) {
        return (generatedAssetLinks != null &&
                generatedAssetLinks.errorCode.isNotEmpty)
            ? Text(
                '无法生成 assetlinks.json，因为应用 ${controller.applicationId} 未上传到 Google Play',
                style: theme.subtleTextStyle,
              )
            : _CodeCard(content: generatedAssetLinks?.generatedString);
      },
    );
  }
}

class _FailureDetails extends StatelessWidget {
  const _FailureDetails({required this.errors, this.oneFixGuideForAll});

  final List<CommonError> errors;
  final String? oneFixGuideForAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final error in errors) ...[
          const SizedBox(height: densePadding),
          Text('问题：${error.title}'),
          const SizedBox(height: densePadding),
          Text(error.explanation, style: Theme.of(context).subtleTextStyle),
          if (oneFixGuideForAll == null) ...[
            const SizedBox(height: defaultSpacing),
            const Text('修复指南：'),
            const SizedBox(height: densePadding),
            Text(error.fixDetails, style: Theme.of(context).subtleTextStyle),
          ],
        ],
        if (oneFixGuideForAll != null) ...[
          const SizedBox(height: defaultSpacing),
          const Text('修复指南：'),
          const SizedBox(height: densePadding),
          Text(oneFixGuideForAll!, style: Theme.of(context).subtleTextStyle),
        ],
      ],
    );
  }
}

class _DomainAssociatedLinksPanel extends StatelessWidget {
  const _DomainAssociatedLinksPanel({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkData = controller.selectedLink.value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('关联的深度链接 URL', style: theme.textTheme.titleMedium),
        Card(
          color: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(denseSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: linkData.associatedPath
                  .map(
                    (path) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: denseRowSpacing,
                      ),
                      child: Row(
                        children: <Widget>[
                          if (linkData.domainErrors.isNotEmpty)
                            Icon(
                              Icons.error,
                              color: theme.colorScheme.error,
                              size: defaultIconSize,
                            ),
                          const SizedBox(width: denseSpacing),
                          Text('${linkData.domain}$path'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CrossCheckTable extends StatelessWidget {
  const _CrossCheckTable({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final linkData = controller.selectedLink.value!;

    final hasIosAasaFile = linkData.hasIosAasaFile;
    final hasAndroidAssetLinksFile = linkData.hasAndroidAssetLinksFile;

    final missingIos = hasIosAasaFile && !linkData.os.contains(PlatformOS.ios);
    final missingAndroid =
        hasAndroidAssetLinksFile && !linkData.os.contains(PlatformOS.android);
    if (!missingIos && !missingAndroid) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final domainMissing = Text(
      '域名缺失',
      style: theme.regularTextStyleWithColor(
        theme.colorScheme.onWarningContainerLink,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: intermediateSpacing),
        Text('应用检查', style: theme.textTheme.titleMedium),
        const SizedBox(height: intermediateSpacing),
        const _CheckTableHeader(),
        const Divider(height: 1.0),
        if (missingAndroid)
          _CheckExpansionTile(
            os: PlatformOS.android,
            checkName: '清单文件',
            status: domainMissing,
            children: const <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultSpacing),
                child: Text(
                  '此域名有 Asset link json 文件，但在 Android manifest 文件中缺失。'
                  '如果你要为 Android 设置深度链接，需要将此域名添加到 AndroidManifest.xml 文件中。',
                ),
              ),
            ],
          ),
        if (missingIos)
          _CheckExpansionTile(
            os: PlatformOS.ios,
            checkName: '设置',
            status: domainMissing,
            children: const <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultSpacing),
                child: Text(
                  '此域名有 AASA 文件，但在本地设置中缺失。'
                  '如果你要为 iOS 设置深度链接，需要将此域名添加到 info.Plist 文件中。',
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PathCheckTable extends StatelessWidget {
  const _PathCheckTable({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final linkData = controller.selectedLink.value!;
    if (!linkData.os.contains(PlatformOS.android)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: intermediateSpacing),
        Text('应用检查', style: theme.textTheme.titleMedium),
        const SizedBox(height: intermediateSpacing),
        const _CheckTableHeader(),
        const Divider(height: 1.0),
        _ManifestFileCheck(controller: controller),
        const Divider(height: 1.0),
        _PathFormatCheck(controller: controller),
      ],
    );
  }
}

class _ManifestFileCheck extends StatelessWidget {
  const _ManifestFileCheck({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final linkData = controller.selectedLink.value!;
    final errors = manifestFileErrors
        .where((error) => linkData.pathErrors.contains(error))
        .toList();

    return _CheckExpansionTile(
      os: PlatformOS.android,
      checkName: '清单文件',
      status: _CheckStatusText(hasError: errors.isNotEmpty),
      children: <Widget>[
        if (errors.isNotEmpty)
          _IssuesBorderWrap(
            children: [
              _FailureDetails(
                errors: errors,
                oneFixGuideForAll:
                    '将以下代码复制到你的 Manifest 文件中。',
              ),
              const _CodeCard(
                content: '''$metaDataDeepLinkingFlagTag

<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
</intent-filter>''',
              ),
            ],
          ),
      ],
    );
  }
}

class _PathFormatCheck extends StatelessWidget {
  const _PathFormatCheck({required this.controller});

  final DeepLinksController controller;

  @override
  Widget build(BuildContext context) {
    final linkData = controller.selectedLink.value!;
    final hasError = linkData.pathErrors.contains(PathError.pathFormat);

    return _CheckExpansionTile(
      os: PlatformOS.android,
      checkName: 'URL 格式',
      status: _CheckStatusText(hasError: hasError),
      children: <Widget>[
        if (hasError)
          const _IssuesBorderWrap(
            children: [
              _FailureDetails(errors: [PathError.pathFormat]),
            ],
          ),
      ],
    );
  }
}

class _CheckTableHeader extends StatelessWidget {
  const _CheckTableHeader();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.deeplinkTableHeaderColor,
      title: const Padding(
        padding: EdgeInsets.only(
          left: defaultSpacing,
          right: defaultSpacing + actionsIconSize,
        ),
        child: Row(
          children: [
            Expanded(child: Text('OS')),
            Expanded(child: Text('问题类型')),
            Expanded(child: Text('状态')),
          ],
        ),
      ),
    );
  }
}

class _CheckExpansionTile extends StatelessWidget {
  const _CheckExpansionTile({
    required this.os,
    required this.checkName,
    required this.status,
    required this.children,
    this.initiallyExpanded = false,
  });

  final PlatformOS os;
  final String checkName;
  final Widget status;
  final bool initiallyExpanded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Row(
      children: [
        const SizedBox(width: defaultSpacing),
        Expanded(child: Text(os == PlatformOS.ios ? 'iOS' : 'Android')),
        Expanded(child: Text(checkName)),
        Expanded(child: status),
      ],
    );
    if (children.isEmpty) {
      return ListTile(
        tileColor: theme.colorScheme.alternatingBackgroundColor2,
        title: title,
        trailing: const SizedBox(width: actionsIconSize),
      );
    }
    return ExpansionTile(
      backgroundColor: theme.colorScheme.alternatingBackgroundColor2,
      collapsedBackgroundColor: theme.colorScheme.alternatingBackgroundColor2,
      initiallyExpanded: initiallyExpanded,
      title: title,
      children: children,
    );
  }
}

class _IssuesBorderWrap extends StatelessWidget {
  const _IssuesBorderWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: largeSpacing,
        vertical: densePadding,
      ),
      child: RoundedOutlinedBorder(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: largeSpacing,
            vertical: densePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _CheckStatusText extends StatelessWidget {
  const _CheckStatusText({required this.hasError});

  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return hasError
        ? Text('检查失败', style: theme.errorTextStyle)
        : Text(
            '未发现问题',
            style: TextStyle(color: theme.colorScheme.green),
          );
  }
}

class _VerifiedOrErrorText extends StatelessWidget {
  const _VerifiedOrErrorText(this.text, {required this.isError});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        isError
            ? Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.error,
                size: defaultIconSize,
              )
            : Icon(
                Icons.verified,
                color: Theme.of(context).colorScheme.green,
                size: defaultIconSize,
              ),
        const SizedBox(width: denseSpacing),
        Text(text),
      ],
    );
  }
}
