/*
 * SPDX-FileCopyrightText: 2024 okaycode.dev LLC and Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../background/background.dart';
import '../model/alerts.dart';
import 'alerts_event.dart';
import 'alerts_state.dart';

class AlertsBloc extends Bloc<AlertEvent, AlertState> {
  AlertsBloc({required BackgroundWorker bgWorker})
      : _bgWorker = bgWorker,
        super(AlertsInit(alerts: [], sources: [])) {
    on<ListenForAlerts>(_listenForAlerts);
    on<AddAlertSource>(_addSource);
    on<UpdateAlertSource>(_updateSource);
    on<RemoveAlertSource>(_removeSource);
    on<FetchAlerts>(_fetch, transformer: droppable());
    if (!Platform.isAndroid && !Platform.isIOS) {
      player = AudioPlayer();
    }
    add(ListenForAlerts());
  }

  final BackgroundWorker _bgWorker;
  late AudioPlayer? player;

  Future<void> _addSource(
      AddAlertSource event, Emitter<AlertState> emit) async {
    _bgWorker.makeRequest(IsolateMessage(
        name: MessageName.addSource, sourceStrings: event.source));
  }

  Future<void> _updateSource(
      UpdateAlertSource event, Emitter<AlertState> emit) async {
    _bgWorker.makeRequest(IsolateMessage(
        name: MessageName.updateSource,
        id: event.id,
        sourceStrings: event.source));
  }

  Future<void> _removeSource(
      RemoveAlertSource event, Emitter<AlertState> emit) async {
    _bgWorker.makeRequest(
        IsolateMessage(name: MessageName.removeSource, id: event.id));
  }

  Future<void> _fetch(FetchAlerts event, Emitter<AlertState> emit) async {
    _bgWorker.makeRequest(IsolateMessage(
        name: MessageName.fetchAlerts, forceRefreshNow: event.forceRefreshNow));
  }

  Future<void> _listenForAlerts(
      ListenForAlerts event, Emitter<AlertState> emit) async {
    List<Alert> alerts = [];
    List<AlertSource> sources = [];
    await for (final data
        in _bgWorker.isolateStreams[MessageDestination.alerts]!.stream) {
      alerts = data.alerts ?? alerts;
      sources = data.sources ?? sources;
      if (data.name == MessageName.alertsInit) {
        emit(AlertsInit(alerts: alerts, sources: sources));
      } else if (data.name == MessageName.alertsFetching) {
        emit(AlertsFetching(alerts: alerts, sources: sources));
      } else if (data.name == MessageName.alertsFetched) {
        emit(AlertsFetched(alerts: alerts, sources: sources));
      } else if (data.name == MessageName.sourcesChanged) {
        emit(SourcesChanged(alerts: alerts, sources: sources));
      } else if (data.name == MessageName.playDesktopSound) {
        if (!Platform.isAndroid && !Platform.isIOS) {
          player?.play(AssetSource("sound/alarm.ogg"));
        }
      } else {
        throw "OAV Invalid 'alert' stream message name: ${data.name}";
      }
    }
  }
}
