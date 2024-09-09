/*
 * SPDX-FileCopyrightText: 2024 okaycode.dev LLC and Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 * 
 * Based on BSD 3-Clause code from:
 * <https://dart.dev/language/isolates#complete-example>
 */

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart';

import '../alerts/model/alerts.dart';
import '../app/data_repository/settings_repository.dart';
import '../app/data_source/database.dart';
import 'repo/alerts.dart';
import 'repo/notifications.dart';
import 'repo/sources.dart';

enum MessageName {
  alertsInit,
  alertsFetching,
  alertsFetched,
  fetchAlerts,
  refreshTimer,
  addSource,
  updateSource,
  removeSource,
  enableNotifications,
  disableNotifications,
  toggleSounds,
  playDesktopSound,
  sourcesChanged,
  sourcesFailure,
  showRefreshIndicator,
}

enum MessageDestination {
  alerts,
  notifications,
  refreshIcon,
}

class IsolateMessage {
  const IsolateMessage(
      {required this.name,
      this.destination,
      this.id,
      this.alerts,
      this.sourceMap,
      this.sources,
      this.forceRefreshNow,
      this.alreadyFetching});
  final MessageName name;
  final MessageDestination? destination;
  final int? id;
  final List<Alert>? alerts;
  final Map<String, Object>? sourceMap;
  final List<AlertSource>? sources;
  final bool? forceRefreshNow;
  final bool? alreadyFetching;
}

class BackgroundWorker {
  BackgroundWorker() {
    for (var destination in MessageDestination.values) {
      isolateStreams[destination] = StreamController<IsolateMessage>();
    }
  }

  final Map<MessageDestination, StreamController<IsolateMessage>>
      isolateStreams = {};
  final Completer<void> _isolateReady = Completer.sync();
  late SendPort _sendPort;
  static late LocalDatabase db;
  static late SettingsRepo settings;
  static late SourcesRepo sourcesRepo;
  static late AlertsRepo alertsRepo;
  static late NotificationRepo notifier;

  Future<void> spawn({required String appVersion}) async {
    final receivePort = ReceivePort();
    receivePort.listen(_handleResponsesFromIsolate);
    var isolate = await Isolate.spawn(_startRemoteIsolate,
        (receivePort.sendPort, RootIsolateToken.instance, appVersion));
    isolate.addErrorListener(receivePort.sendPort);
  }

  Future<void> makeRequest(IsolateMessage message) async {
    await _isolateReady.future;
    _sendPort.send(message);
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
      _isolateReady.complete();
    } else if (message is IsolateMessage) {
      isolateStreams[message.destination]?.add(message);
    } else if (message is List<Object>) {
      isolateStreams[MessageDestination.alerts]!
          .add(IsolateMessage(name: MessageName.alertsFetched, alerts: [
        const Alert(
            source: 0,
            kind: AlertType.syncFailure,
            hostname: "Open Alert Viewer",
            service: "Background Isolate",
            message: "Oh no! The background isolate has stopped. "
                "Please check whether an app upgrade is available and "
                "resolves this issue. If that does not help, "
                "please take a screen shot, and submit it using "
                "the link icon to the left so we can help resolve the "
                "problem. Sorry for the inconvenience.",
            url: "https://github.com/okaycode-dev/open_alert_viewer/issues",
            age: Duration.zero),
        Alert(
            source: 0,
            kind: AlertType.syncFailure,
            hostname: "Open Alert Viewer version ${SettingsRepo.appVersion}",
            service: "Stack Trace",
            message: message.toString(),
            url: "https://github.com/okaycode-dev/open_alert_viewer/issues",
            age: Duration.zero),
      ]));
    } else {
      throw Exception("Invalid message type: $message");
    }
  }

  static void _startRemoteIsolate(
      (SendPort, RootIsolateToken?, String) init) async {
    SendPort port;
    RootIsolateToken token;
    String appVersion;
    (port, token!, appVersion) = init;
    final receivePort = ReceivePort();
    port.send(receivePort.sendPort);
    BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    db = LocalDatabase();
    await db.open();
    SettingsRepo.appVersion = appVersion;
    settings = SettingsRepo(db: db);
    sourcesRepo = SourcesRepo(db: db);
    notifier = NotificationRepo(settings: settings);
    await notifier.initializeAlertNotifications();
    await notifier.startAnroidStickyNotification();
    var outboundStream = StreamController<IsolateMessage>();
    alertsRepo = AlertsRepo(
        db: db,
        settings: settings,
        sourcesRepo: sourcesRepo,
        notifier: notifier);
    alertsRepo.init(outboundStream);
    outboundStream.stream.listen((event) {
      if (event.destination == null) {
        throw Exception(
            "Background worker sending message without destination");
      }
      port.send(event);
    });
    receivePort.listen((dynamic message) async {
      if (message is IsolateMessage) {
        if (message.name == MessageName.fetchAlerts) {
          alertsRepo.fetchAlerts(
              forceRefreshNow: message.forceRefreshNow ?? false);
        } else if (message.name == MessageName.refreshTimer) {
          alertsRepo.refreshTimer();
        } else if (message.name == MessageName.addSource) {
          var result = await sourcesRepo.addSource(source: message.sourceMap!);
          _sourcesChangeResult(port, (result >= 0));
        } else if (message.name == MessageName.updateSource) {
          var result =
              await sourcesRepo.updateSource(source: message.sourceMap!);
          _sourcesChangeResult(port, result);
        } else if (message.name == MessageName.removeSource) {
          sourcesRepo.removeSource(id: message.id!);
          _sourcesChangeResult(port, true);
        } else if (message.name == MessageName.enableNotifications) {
          notifier.startAnroidStickyNotification();
        } else if (message.name == MessageName.disableNotifications) {
          notifier.disableNotifications();
        } else if (message.name == MessageName.toggleSounds) {
          notifier.updateAlertDetails();
        } else {
          throw Exception("Invalid message name: $message");
        }
      } else {
        throw Exception("Invalid message type: $message");
      }
    });
  }

  static void _sourcesChangeResult(SendPort port, bool success) {
    if (success) {
      port.send(const IsolateMessage(name: MessageName.sourcesChanged));
      alertsRepo.fetchAlerts(forceRefreshNow: true);
    } else {
      port.send(const IsolateMessage(name: MessageName.sourcesFailure));
    }
  }
}
