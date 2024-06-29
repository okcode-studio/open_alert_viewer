/*
 * SPDX-FileCopyrightText: 2024 okaycode.dev LLC and Open Alert Viewer Authors
 *
 * SPDX-License-Identifier: MIT
 */

part of 'settings_bloc.dart';

abstract class SettingsState {
  const SettingsState();
}

final class SettingsInitial extends SettingsState {}

final class SettingsChanged extends SettingsState {
  SettingsChanged({required this.settings});

  final Map<String, Object> settings;
}
