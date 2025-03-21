/*
 * SPDX-FileCopyrightText: 2024 Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/settings_repo.dart';
import '../../../domain/navigation.dart';
import '../widgets/settings_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.title});

  final String title;

  static Route<void> route({required title}) {
    return MaterialPageRoute<void>(builder: (_) => AboutScreen(title: title));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralHeader(title: title),
      body: const AboutList(),
    );
  }
}

class AboutList extends StatelessWidget {
  const AboutList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        MenuItem(
          icon: Icons.article_outlined,
          title: "App and License Info",
          onTap: () async {
            context.read<Navigation>().goTo(Screens.licensing);
          },
        ),
        MenuItem(
          icon: Icons.person_search_outlined,
          title: "Privacy Policy",
          onTap: () async {
            context.read<Navigation>().goTo(Screens.privacy);
          },
        ),
        MenuItem(
          icon: Icons.support_outlined,
          title: "Online Support",
          onTap: () async {
            var link = "https://github.com/sandpiper-codes/open_alert_viewer";
            try {
              var uri = Uri.parse(link);
              await launchUrl(uri);
            } catch (e) {
              log("Error launching URL: $link");
            }
          },
        ),
        MenuItem(
          icon: Icons.volunteer_activism_outlined,
          title: "Donate",
          onTap: () async {
            var link = "https://buymeacoffee.com/sandpiper.codes";
            try {
              var uri = Uri.parse(link);
              await launchUrl(uri);
            } catch (e) {
              log("Error launching URL: $link");
            }
          },
        ),
        MenuItem(
          icon: Icons.info_outline,
          title: "Open Alert Viewer version",
          subtitle: SettingsRepo.appVersion,
          onTap: () {},
        ),
      ],
    );
  }
}
