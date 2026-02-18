// Copyright 2022 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'dart:async';

import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/analytics/constants.dart' as gac;
import '../../shared/globals.dart';
import '../../shared/ui/common_widgets.dart';
import '../../shared/utils/utils.dart';
import '../release_notes.dart';

class DevToolsAboutDialog extends StatelessWidget {
  const DevToolsAboutDialog(this.releaseNotesController, {super.key});

  final ReleaseNotesController releaseNotesController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DevToolsDialog(
      title: const DialogTitleText('关于 DevTools'),
      content: SelectionArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                Text('DevTools 版本 $devToolsVersion'),
                const Text(' - '),
                InkWell(
                  child: Text('发布日志', style: theme.linkTextStyle),
                  onTap: () => unawaited(
                    releaseNotesController.openLatestReleaseNotes(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: denseSpacing),
            const Wrap(
              children: [
                Text('遇到问题了吗？请告诉我们 '),
                _FeedbackLink(),
                Text('.'),
              ],
            ),
            const SizedBox(height: defaultSpacing),
            ...dialogSubHeader(theme, '贡献'),
            const Wrap(
              children: [
                Text('想要为 DevTools 做贡献吗？请参阅我们的 '),
                _ContributingLink(),
                Text(' 指导手册，或者 '),
              ],
            ),

            const Wrap(
              children: [
                Text('关注我们 '),
                _DiscordLink(),
                Text('.'),
              ],
            ),
          ],
        ),
      ),
      actions: const [DialogLicenseButton(), DialogCloseButton()],
    );
  }
}

class _FeedbackLink extends StatelessWidget {
  const _FeedbackLink();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: GaLinkTextSpan(
        link: devToolsEnvironmentParameters.issueTrackerLink(),
        context: context,
      ),
    );
  }
}

class _ContributingLink extends StatelessWidget {
  const _ContributingLink();

  static const _contributingGuideUrl =
      'https://github.com/flutter/devtools/blob/master/CONTRIBUTING.md';

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: GaLinkTextSpan(
        link: const GaLink(
          display: 'CONTRIBUTING',
          url: _contributingGuideUrl,
          gaScreenName: gac.devToolsMain,
          gaSelectedItemDescription: gac.contributingLink,
        ),
        context: context,
      ),
    );
  }
}

class _DiscordLink extends StatelessWidget {
  const _DiscordLink();

  static const _discordDocsUrl =
      'https://github.com/flutter/flutter/blob/master/docs/contributing/Chat.md';

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: GaLinkTextSpan(
        link: const GaLink(
          display: 'Discord',
          url: _discordDocsUrl,
          gaScreenName: gac.devToolsMain,
          gaSelectedItemDescription: gac.discordLink,
        ),
        context: context,
      ),
    );
  }
}

class OpenAboutAction extends ScaffoldAction {
  OpenAboutAction({super.key, super.color})
    : super(
        icon: Icons.help_outline,
        tooltip: '关于 DevTools',
        onPressed: (context) {
          unawaited(
            showDialog(
              context: context,
              builder: (context) => DevToolsAboutDialog(
                Provider.of<ReleaseNotesController>(context),
              ),
            ),
          );
        },
      );
}

// Since [DevToolsAboutDialog] is not actually an [AboutDialog], there is no
// built-in way to add a 'View Licenses' button.
// So, adding a custom [DialogTextButton] to view licenses.
// Since this action is very specific to just the [DevToolsAboutDialog],
// providing implementation in about_dialog.dart and not in
// dialogs.dart which contains the definition of [DevToolsDialog].
// TODO(mossmana): We may want to consider refactoring [DevToolsAboutDialog] to
// be an [AboutDialog].
// https://api.flutter.dev/flutter/material/AboutDialog-class.html
final class DialogLicenseButton extends StatelessWidget {
  const DialogLicenseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return DialogTextButton(
      onPressed: () {
        showLicensePage(
          context: context,
          applicationName: 'DevTools',
          useRootNavigator: true,
        );
      },
      child: const Text('查看许可证'),
    );
  }
}
