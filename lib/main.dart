/*
 * SPDX-FileCopyrightText: 2024 Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import 'app.dart';
import 'data/services/database.dart';
import 'background/background.dart';
import 'background/background_desktop.dart';
import 'background/background_mobile.dart';

LocalDatabase? db;
BackgroundChannel? bgChannel;

Future<void> main() async {
  await startBackground();
  await startForeground();
}

Future<void> startBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (db == null) {
    db = LocalDatabase();
    await db!.migrate(showPath: true);
  }
  if (bgChannel == null) {
    if (Platform.isAndroid) {
      bgChannel = BackgroundMobile();
    } else {
      bgChannel = BackgroundDesktop();
    }
    await bgChannel!.spawn(appVersion: await getVersion());
  }
}

Future<void> startForeground() async {
  while (bgChannel == null || db == null) {
    await Future.delayed(Duration(milliseconds: 100));
  }
  runApp(
      OAVapp(appVersion: await getVersion(), db: db!, bgChannel: bgChannel!));
}

Future<String> getVersion() async {
  try {
    String gitVersion;
    final pubspecVersion =
        loadYaml(await rootBundle.loadString("pubspec.yaml"))["version"];
    var head = await rootBundle.loadString('.git/HEAD');
    if (head.startsWith('ref: refs/heads/')) {
      final branchName = head.split('ref: refs/heads/').last.trim();
      gitVersion = await rootBundle.loadString('.git/refs/heads/$branchName');
    } else {
      gitVersion = head;
    }
    return "$pubspecVersion-${gitVersion.substring(0, 8)}";
  } catch (e) {
    return "version-unknown";
  }
}
