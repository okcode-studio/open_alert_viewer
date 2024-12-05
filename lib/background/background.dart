/*
 * SPDX-FileCopyrightText: 2024 Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'dart:isolate';

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
  updateLastSeen,
  confirmSources,
  confirmSourcesReply,
}

enum MessageDestination {
  alerts,
  notifications,
  refreshIcon,
  accountSettings,
}

class IsolateMessage {
  const IsolateMessage(
      {required this.name,
      this.destination,
      this.id,
      this.alerts,
      this.sourceData,
      this.sources,
      this.forceRefreshNow,
      this.alreadyFetching});
  final MessageName name;
  final MessageDestination? destination;
  final int? id;
  final List<Alert>? alerts;
  final AlertSourceData? sourceData;
  final List<AlertSource>? sources;
  final bool? forceRefreshNow;
  final bool? alreadyFetching;
}

abstract class BackgroundChannel {
  Future<void> spawn({required String appVersion});
  Future<void> makeRequest(IsolateMessage message);
  final Map<MessageDestination, StreamController<IsolateMessage>>
      isolateStreams = {};
  static SettingsRepo? settings;
}

mixin BackgroundTranslator {
  String serializeMessage(IsolateMessage message) {
    return '{name: "fetchAlerts"}';
  }

  IsolateMessage deserializeToMessage(String message) {
    return IsolateMessage(name: MessageName.fetchAlerts);
  }
}

class BackgroundChannelResponse with BackgroundTranslator {
  BackgroundChannelResponse() {
    for (var destination in MessageDestination.values) {
      isolateStreams[destination] = StreamController<IsolateMessage>();
    }
  }
  final Map<MessageDestination, StreamController<IsolateMessage>>
      isolateStreams = {};
  final Completer<void> isolateReady = Completer.sync();
  late SendPort sendPort;

  void handleResponsesFromBackground(dynamic message) {
    if (message is SendPort) {
      sendPort = message;
      isolateReady.complete();
    } else if (message is IsolateMessage) {
      isolateStreams[message.destination]!.add(message);
    } else if (message is List<dynamic>) {
      isolateStreams[MessageDestination.alerts]!
          .add(IsolateMessage(name: MessageName.alertsFetched, alerts: [
        const Alert(
            source: 0,
            kind: AlertType.syncFailure,
            hostname: "Open Alert Viewer",
            service: "Background Isolate",
            message: "Oh no! The background isolate crashed. "
                "Please check whether an app upgrade is available and "
                "resolves this issue. If that does not help, "
                "please take a screen shot, and submit it using "
                "the link icon to the left so we can help resolve the "
                "problem. Sorry for the inconvenience.",
            url: "https://github.com/okcode-studio/open_alert_viewer/issues",
            age: Duration.zero,
            silenced: false,
            downtimeScheduled: false,
            active: true),
        Alert(
            source: 0,
            kind: AlertType.syncFailure,
            hostname: "Open Alert Viewer version ${SettingsRepo.appVersion}",
            service: "Stack Trace",
            message: message.toString(),
            url: "https://github.com/okcode-studio/open_alert_viewer/issues",
            age: Duration.zero,
            silenced: false,
            downtimeScheduled: false,
            active: true),
      ]));
    } else {
      throw Exception("Invalid message type: $message");
    }
  }
}

class BackgroundChannelReceiver with BackgroundTranslator {
  late LocalDatabase _db;
  late SettingsRepo _settings;
  late SourcesRepo _sourcesRepo;
  late AlertsRepo _alertsRepo;
  late NotificationRepo _notifier;
  late StreamController<IsolateMessage> _outboundStream;

  Future<StreamController<IsolateMessage>> init(String appVersion) async {
    _db = LocalDatabase();
    await _db.open();
    SettingsRepo.appVersion = appVersion;
    _settings = SettingsRepo(db: _db);
    BackgroundChannel.settings = _settings;
    _notifier = NotificationRepo(settings: _settings);
    await _notifier.initializeAlertNotifications();
    await _notifier.startAnroidStickyNotification();
    _outboundStream = StreamController<IsolateMessage>();
    _sourcesRepo = SourcesRepo(
        db: _db, outboundStream: _outboundStream, settings: _settings);
    _alertsRepo = AlertsRepo(
        db: _db,
        settings: _settings,
        sourcesRepo: _sourcesRepo,
        notifier: _notifier);
    _alertsRepo.init(_outboundStream);
    return _outboundStream;
  }

  void handleRequestsToBackground(dynamic message) async {
    if (message is IsolateMessage) {
      if (message.name == MessageName.fetchAlerts) {
        _alertsRepo.fetchAlerts(
            forceRefreshNow: message.forceRefreshNow ?? false);
      } else if (message.name == MessageName.refreshTimer) {
        _alertsRepo.refreshTimer();
      } else if (message.name == MessageName.confirmSources) {
        _sourcesRepo.confirmSource(message);
      } else if (message.name == MessageName.addSource) {
        _sourcesRepo.addSource(sourceData: message.sourceData!);
      } else if (message.name == MessageName.updateSource) {
        _sourcesRepo.updateSource(
            sourceData: message.sourceData!, updateUIandRefresh: true);
      } else if (message.name == MessageName.removeSource) {
        _sourcesRepo.removeSource(id: message.id!);
      } else if (message.name == MessageName.updateLastSeen) {
        _sourcesRepo.updateLastSeen();
      } else if (message.name == MessageName.enableNotifications) {
        _notifier.startAnroidStickyNotification();
      } else if (message.name == MessageName.disableNotifications) {
        _notifier.disableNotifications();
      } else if (message.name == MessageName.toggleSounds) {
        _notifier.updateAlertDetails();
      } else {
        throw Exception("Invalid message name: $message");
      }
    } else {
      throw Exception("Invalid message type: $message");
    }
  }
}
