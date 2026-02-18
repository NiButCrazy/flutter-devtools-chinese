// Copyright 2023 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_shared/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../shared/analytics/analytics.dart' as ga;
import '../shared/analytics/constants.dart' as gac;
import '../shared/framework/routing.dart';
import '../shared/globals.dart';
import '../shared/ui/common_widgets.dart';

class EmbeddedExtensionHeader extends StatelessWidget {
  const EmbeddedExtensionHeader({
    super.key,
    required this.ext,
    required this.onForceReload,
  });

  final DevToolsExtensionConfig ext;

  final VoidCallback onForceReload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extensionName = ext.displayName;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: borderPadding),
            child: RichText(
              text: TextSpan(
                text: 'package:$extensionName 扩展',
                style: theme.regularTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: ' (v${ext.version})',
                    style: theme.subtleTextStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: denseSpacing),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: GaLinkTextSpan(
                  link: GaLink(
                    display: '报告问题',
                    url: ext.issueTrackerLink,
                    gaScreenName:
                        gac.DevToolsExtensionEvents.extensionScreenId.name,
                    gaSelectedItemDescription:
                        gac.DevToolsExtensionEvents.extensionFeedback(ext),
                  ),
                  context: context,
                ),
              ),
              const SizedBox(width: denseSpacing),
              _ExtensionContextMenuButton(
                ext: ext,
                onForceReload: onForceReload,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExtensionContextMenuButton extends StatelessWidget {
  const _ExtensionContextMenuButton({
    required this.ext,
    required this.onForceReload,
  });

  final DevToolsExtensionConfig ext;

  final VoidCallback onForceReload;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ExtensionEnabledState>(
      valueListenable: extensionService.enabledStateListenable(ext.displayName),
      builder: (context, activationState, _) {
        if (activationState != ExtensionEnabledState.enabled) {
          return const SizedBox.shrink();
        }
        return ContextMenuButton(
          iconSize: defaultIconSize,
          buttonWidth: buttonMinWidth,
          menuChildren: <Widget>[
            PointerInterceptor(
              child: MenuItemButton(
                onPressed: () {
                  // Do not send analytics here because the user must
                  // confirm that they want to disable the extension from
                  // the [DisableExtensionDialog]. Analytics will be sent
                  // there if they confirm that they'd like to disable the
                  // extension.
                  unawaited(
                    showDialog(
                      context: context,
                      builder: (_) => DisableExtensionDialog(ext: ext),
                    ),
                  );
                },
                child: const MaterialIconLabel(
                  label: '禁用扩展',
                  iconData: Icons.extension_off_outlined,
                ),
              ),
            ),
            PointerInterceptor(
              child: MenuItemButton(
                onPressed: () {
                  ga.select(
                    gac.DevToolsExtensionEvents.extensionScreenId.name,
                    gac.DevToolsExtensionEvents.extensionForceReload(ext),
                  );
                  onForceReload();
                },
                child: const MaterialIconLabel(
                  label: '强制重新加载扩展',
                  iconData: Icons.refresh,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

@visibleForTesting
class DisableExtensionDialog extends StatelessWidget {
  const DisableExtensionDialog({super.key, required this.ext});

  final DevToolsExtensionConfig ext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevToolsDialog(
      title: const DialogTitleText('禁用扩展程序？'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: '您确定要禁用 ',
              style: theme.regularTextStyle,
              children: [
                TextSpan(text: ext.displayName, style: theme.fixedFontStyle),
                const TextSpan(text: ' 扩展吗？'),
              ],
            ),
          ),
          const SizedBox(height: denseSpacing),
          RichText(
            text: TextSpan(
              text: '您稍后可以从该菜单随时重新启用此扩展程序 ',
              style: theme.regularTextStyle,
              children: [
                TextSpan(
                  text: 'DevTools 扩展 ',
                  style: theme.boldTextStyle,
                ),
                const WidgetSpan(
                  child: Icon(Icons.extension_rounded, size: defaultIconSize),
                ),
                const TextSpan(text: ''),
              ],
            ),
          ),
        ],
      ),
      actions: [
        DialogTextButton(
          onPressed: () {
            ga.select(
              gac.DevToolsExtensionEvents.extensionScreenId.name,
              gac.DevToolsExtensionEvents.extensionDisableManual(ext),
            );
            unawaited(
              extensionService.setExtensionEnabledState(ext, enable: false),
            );
            Navigator.of(context).pop(dialogDefaultContext);
            DevToolsRouterDelegate.of(
              context,
            ).navigateHome(clearScreenParam: true);
          },
          child: const Text('是的，禁用'),
        ),
        const DialogCancelButton(),
      ],
    );
  }
}

class EnableExtensionPrompt extends StatelessWidget {
  const EnableExtensionPrompt({super.key, required this.ext});

  final DevToolsExtensionConfig ext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: '该 ',
              style: theme.regularTextStyle,
              children: [
                TextSpan(text: ext.name, style: theme.fixedFontStyle),
                const TextSpan(
                  text:
                      ' 扩展尚未启用，您想要启用这个扩展吗？\n'
                      '您可以随时在 DevTools 扩展 ',
                ),
                WidgetSpan(
                  child: Icon(
                    Icons.extension_outlined,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const TextSpan(text: ' 菜单中更改该设置'),
              ],
            ),
          ),
          const SizedBox(height: defaultSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GaDevToolsButton(
                label: '开启',
                gaScreen: gac.DevToolsExtensionEvents.extensionScreenId.name,
                gaSelection: gac.DevToolsExtensionEvents.extensionEnablePrompt(
                  ext,
                ),
                elevated: true,
                onPressed: () {
                  unawaited(
                    extensionService.setExtensionEnabledState(
                      ext,
                      enable: true,
                    ),
                  );
                },
              ),
              const SizedBox(width: defaultSpacing),
              GaDevToolsButton(
                label: '不，隐藏此界面',
                gaScreen: gac.DevToolsExtensionEvents.extensionScreenId.name,
                gaSelection: gac.DevToolsExtensionEvents.extensionDisablePrompt(
                  ext,
                ),
                onPressed: () {
                  unawaited(
                    extensionService.setExtensionEnabledState(
                      ext,
                      enable: false,
                    ),
                  );
                  DevToolsRouterDelegate.of(
                    context,
                  ).navigateHome(clearScreenParam: true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
