/*
 * SPDX-FileCopyrightText: 2024 Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'package:bloc/bloc.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../background/background.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(
      {required SettingsRepo settings, required BackgroundChannel bgChannel})
      : _settingsRepo = settings,
        _bgChannel = bgChannel,
        super(SettingsInitial()) {
    on<SettingsPushEvent>(_pushSettings);

    add(SettingsPushEvent(newSettings: {}));
  }

  final SettingsRepo _settingsRepo;
  final BackgroundChannel _bgChannel;

  void _pushSettings(SettingsPushEvent event, Emitter<SettingsState> emit) {
    for (var setting in event.newSettings.keys) {
      var newSetting = event.newSettings[setting];
      switch (setting) {
        case "refreshInterval":
          _settingsRepo.refreshInterval = newSetting;
          _bgChannel.makeRequest(
              const IsolateMessage(name: MessageName.refreshTimer));
        case "syncTimeout":
          _settingsRepo.syncTimeout = newSetting;
        case "notificationsRequested":
          _settingsRepo.notificationsRequested = newSetting;
        case "notificationsEnabled":
          _settingsRepo.notificationsEnabled = newSetting;
        case "soundEnabled":
          _settingsRepo.soundEnabled = newSetting;
        case "alertFilter":
          _settingsRepo.alertFilter = newSetting;
        case "setAlertFilterAt":
          bool value;
          int index;
          (value, index) = newSetting as (bool, int);
          _settingsRepo.setAlertFilterAt(value, index);
        case "silenceFilter":
          _settingsRepo.silenceFilter = newSetting;
        case "setSilenceFilterAt":
          bool value;
          int index;
          (value, index) = newSetting as (bool, int);
          _settingsRepo.setSilenceFilterAt(value, index);
        case "darkMode":
          _settingsRepo.darkMode = newSetting;
        case _:
          throw Exception("Unsupported setting: $setting");
      }
    }
    emit(SettingsChanged(settings: {
      "refreshInterval": _settingsRepo.refreshInterval,
      "syncTimeout": _settingsRepo.syncTimeout,
      "notificationsRequested": _settingsRepo.notificationsRequested,
      "notificationsEnabled": _settingsRepo.notificationsEnabled,
      "soundEnabled": _settingsRepo.soundEnabled,
      "alertFilter": _settingsRepo.alertFilter,
      "silenceFilter": _settingsRepo.silenceFilter,
      "darkMode": _settingsRepo.darkMode,
    }));
  }
}