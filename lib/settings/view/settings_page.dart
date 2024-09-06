/*
 * SPDX-FileCopyrightText: 2024 okaycode.dev LLC and Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';

import '../../alerts/bloc/alerts_bloc.dart';
import '../../alerts/bloc/alerts_event.dart';
import '../../alerts/bloc/alerts_state.dart';
import '../../alerts/model/alerts.dart';
import '../../app/view/app_view_elements.dart';
import '../../navigation/bloc/navigation_bloc.dart';
import '../../navigation/bloc/navigation_event.dart';
import '../../app/data_repository/settings_repository.dart';
import '../../notifications/bloc/notification_bloc.dart';
import '../bloc/settings_bloc.dart';
import 'settings_components.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  static Route<void> route({required title}) {
    return MaterialPageRoute<void>(builder: (_) => SettingsPage(title: title));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: SettingsHeader(title: title),
        body: BlocListener<AlertsBloc, AlertState>(
            listener: (context, state) {
              switch (state) {
                case SourcesListUpdateError():
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text("Ignoring duplicate of existing alert source")));
              }
            },
            child: const SettingsList()));
  }
}

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key, required this.title});

  final String title;

  static Route<void> route({required title}) {
    return MaterialPageRoute<void>(
        builder: (_) => GeneralSettingsPage(title: title));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: SettingsHeader(title: title),
        body: const GeneralSettingsList());
  }
}

class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertsBloc, AlertState>(builder: (context, state) {
      return ListView(children: [
        MenuItem(
            icon: Icons.settings,
            title: "General Settings",
            onTap: () =>
                context.read<NavBloc>().add(OpenGeneralSettingsPageEvent())),
        const MenuHeaderTile(title: "Accounts"),
        for (AlertSource account in state.sources)
          MenuItem(
              icon: Icons.manage_accounts,
              title: account.name,
              onTap: () => context
                  .read<NavBloc>()
                  .add(OpenAccountSettingsPageEvent(source: account))),
        MenuItem(
            icon: Icons.add,
            title: "Add new account",
            onTap: () => context
                .read<NavBloc>()
                .add(OpenAccountSettingsPageEvent(source: null))),
      ]);
    });
  }
}

enum RefreshFrequencies {
  fifteenSeconds("Every 15 Seconds", 15),
  thirtySeconds("Every 30 Seconds", 30),
  oneMinute("Every Minute", 1 * 60),
  threeMinutes("Every 3 Minutes", 3 * 60),
  fiveMinutes("Every 5 Minutes", 5 * 60),
  fifteenMinutes("Every 15 Minutes", 15 * 60),
  thirtyMinutes("Every 30 Minutes", 30 * 60),
  oneHour("Every Hour", 60 * 60),
  twoHours("Every 2 Hours", 120 * 60),
  off("Off", -1);

  const RefreshFrequencies(this.text, this.value);

  final String text;
  final int value;
}

enum SyncTimeouts {
  oneMinute("5 Seconds", 5),
  threeMinutes("10 Seconds", 10),
  fiveMinutes("15 Seconds", 15),
  fifteenMinutes("30 Seconds", 30),
  thirtyMinutes("45 Seconds", 45),
  oneHour("1 Minute", 60),
  twoHours("2 Minutes", 120),
  off("Off", -1);

  const SyncTimeouts(this.text, this.value);

  final String text;
  final int value;
}

enum ColorModes {
  oneMinute("Auto", -1),
  fiveMinutes("Light Mode", 0),
  threeMinutes("Dark Mode", 1);

  const ColorModes(this.text, this.value);

  final String text;
  final int value;
}

class GeneralSettingsList extends StatelessWidget {
  const GeneralSettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
      var settings = context.read<SettingsRepo>();
      var settingsBloc = context.read<SettingsBloc>();
      var alertsBloc = context.read<AlertsBloc>();
      String refreshIntervalSubtitle = () {
        for (var option in RefreshFrequencies.values) {
          if (option.value == settings.refreshInterval) {
            return option.text;
          }
        }
        return "Every ${settings.refreshInterval} seconds";
      }();
      String syncTimeoutSubtitle = () {
        for (var option in SyncTimeouts.values) {
          if (option.value == settings.syncTimeout) {
            return option.text;
          }
        }
        return "Every ${settings.syncTimeout} seconds";
      }();
      String darkModeSubtitle = () {
        for (var option in ColorModes.values) {
          if (option.value == settings.darkMode) {
            return option.text;
          }
        }
        return "Unknown";
      }();
      return ListView(children: [
        MenuItem(
            icon: Icons.update,
            title: "Refresh Interval",
            subtitle: refreshIntervalSubtitle,
            onTap: () async {
              int? result = await _settingsRadioDialogBuilder<int>(
                  context: context,
                  text: "Refresh Interval",
                  priorSetting: settings.refreshInterval,
                  valueListBuilder: listRefreshFrequencies);
              if (result != null) {
                settingsBloc.add(SettingsPushEvent(
                    newSettings: {"refreshInterval": result}));
              }
            }),
        MenuItem(
            icon: Icons.timer_outlined,
            title: "Sync Timeout",
            subtitle: syncTimeoutSubtitle,
            onTap: () async {
              int? result = await _settingsRadioDialogBuilder<int>(
                  context: context,
                  text: "Sync Timeout",
                  priorSetting: settings.syncTimeout,
                  valueListBuilder: listSyncTimeouts);
              if (result != null) {
                settingsBloc.add(
                    SettingsPushEvent(newSettings: {"syncTimeout": result}));
                alertsBloc.add(FetchAlerts(forceRefreshNow: true));
              }
            }),
        MenuItem(
            icon: settings.notificationsEnabled
                ? Icons.notifications_outlined
                : Icons.notifications_off,
            title: "Notifications",
            subtitle: settings.notificationsEnabled
                ? "Enabled within app"
                : "Disabled",
            onTap: () async {
              if (settings.notificationsEnabled) {
                settingsBloc.add(SettingsPushEvent(
                    newSettings: {"notificationsEnabled": false}));
                context
                    .read<NotificationBloc>()
                    .add(DisableNotificationsEvent());
              } else {
                context
                    .read<NotificationBloc>()
                    .add(RequestAndEnableNotificationEvent(
                        askAgain: true,
                        callback: () {
                          settingsBloc.add(SettingsPushEvent(newSettings: {
                            "notificationsEnabled":
                                settings.notificationsEnabled
                          }));
                        }));
              }
            }),
        if (Platform.isAndroid && settings.notificationsEnabled)
          MenuItem(
              icon: Icons.tune,
              title: "System Settings",
              onTap: () async {
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              }),
        if (settings.notificationsEnabled)
          MenuItem(
              icon: settings.soundEnabled
                  ? Icons.music_note_outlined
                  : Icons.music_off_outlined,
              title: "Play Sound",
              subtitle:
                  settings.soundEnabled ? "Enabled within app" : "Disabled",
              onTap: () async {
                settingsBloc.add(SettingsPushEvent(
                    newSettings: {"soundEnabled": !settings.soundEnabled}));
                context.read<NotificationBloc>().add(ToggleSounds());
              }),
        MenuItem(
            icon: Icons.filter_alt_outlined,
            title: "Alerts Filter",
            onTap: () async {
              await _settingsCheckBoxDialogBuilder<bool>(
                  context: context,
                  text: "Alerts Filter",
                  priorSetting: settings.alertFilter,
                  valueListBuilder: listFiltered);
            }),
        MenuItem(
            icon: Icons.contrast,
            title: "Dark Mode",
            subtitle: darkModeSubtitle,
            onTap: () async {
              int? result = await _settingsRadioDialogBuilder<int>(
                  context: context,
                  text: "Dark Mode",
                  priorSetting: settings.darkMode,
                  valueListBuilder: listColorModes);
              if (result != null) {
                settingsBloc
                    .add(SettingsPushEvent(newSettings: {"darkMode": result}));
              }
            }),
        if (Platform.isAndroid)
          MenuItem(
              icon: Icons.battery_saver_outlined,
              title: "Battery Optimization",
              onTap: () async {
                var link = "https://dontkillmyapp.com";
                bool result = await textDialogBuilder(
                    context: context,
                    text: "For guidance on how to disable battery optimization "
                        "on your Android device, please confirm this message.",
                    okayText: "Open Browser",
                    cancellable: true);
                if (result == true) {
                  var uri = Uri.parse(link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    log("Error launching URL: $link");
                  }
                }
              }),
        MenuItem(
            icon: Icons.article_outlined,
            title: "App and License Info",
            onTap: () async {
              context.read<NavBloc>().add(OpenLicensingPageEvent());
            }),
        MenuItem(
            icon: Icons.support_outlined,
            title: "Online Support",
            onTap: () async {
              var link = "https://github.com/okaycode-dev/open_alert_viewer";
              var uri = Uri.parse(link);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                log("Error launching URL: $link");
              }
            }),
        MenuItem(
            icon: Icons.volunteer_activism_outlined,
            title: "Donate",
            onTap: () async {
              var link = "https://buymeacoffee.com/okaycode.dev";
              var uri = Uri.parse(link);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                log("Error launching URL: $link");
              }
            }),
      ]);
    });
  }
}

Future _settingsRadioDialogBuilder<T>(
    {required BuildContext context,
    required String text,
    required T? priorSetting,
    required Function<T>({T? priorSetting}) valueListBuilder}) async {
  return await showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            child: SizedBox(
                width: 300,
                child: ListView(shrinkWrap: true, children: [
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      children: valueListBuilder<T>(priorSetting: priorSetting))
                ])));
      });
}

Future _settingsCheckBoxDialogBuilder<T>(
    {required BuildContext context,
    required String text,
    required List<bool> priorSetting,
    required Function({required List<bool> priorSetting})
        valueListBuilder}) async {
  return await showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            child: SizedBox(
                width: 300,
                child: ListView(shrinkWrap: true, children: [
                  Column(
                      mainAxisSize: MainAxisSize.min,
                      children: valueListBuilder(priorSetting: priorSetting))
                ])));
      });
}

List<SettingsRadioEnumValue> listRefreshFrequencies<T>({T? priorSetting}) {
  return [
    for (var option in RefreshFrequencies.values)
      SettingsRadioEnumValue<T>(
          title: option.text,
          value: option.value as T,
          priorSetting: priorSetting)
  ];
}

List<SettingsRadioEnumValue> listSyncTimeouts<T>({T? priorSetting}) {
  return [
    for (var option in SyncTimeouts.values)
      SettingsRadioEnumValue<T>(
          title: option.text,
          value: option.value as T,
          priorSetting: priorSetting)
  ];
}

List<SettingsCheckBoxEnumValue> listFiltered(
    {required List<bool> priorSetting}) {
  return [
    for (var option in AlertType.values)
      SettingsCheckBoxEnumValue(
          title: option.name,
          value: priorSetting[option.index],
          index: option.index)
  ];
}

List<SettingsRadioEnumValue> listColorModes<T>({T? priorSetting}) {
  return [
    for (var option in ColorModes.values)
      SettingsRadioEnumValue<T>(
          title: option.text,
          value: option.value as T,
          priorSetting: priorSetting)
  ];
}

class SettingsRadioEnumValue<T> extends StatelessWidget {
  const SettingsRadioEnumValue(
      {super.key,
      required this.title,
      required this.value,
      required this.priorSetting});

  final String title;
  final T value;
  final T? priorSetting;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
        title: Text(title),
        value: value,
        groupValue: priorSetting,
        onChanged: (T? value) {
          Navigator.of(context).pop(value);
        });
  }
}

class SettingsCheckBoxEnumValue extends StatefulWidget {
  const SettingsCheckBoxEnumValue(
      {super.key,
      required this.title,
      required this.value,
      required this.index});

  final String title;
  final bool value;
  final int index;

  @override
  State<SettingsCheckBoxEnumValue> createState() =>
      _SettingsCheckBoxEnumValueState();
}

class _SettingsCheckBoxEnumValueState extends State<SettingsCheckBoxEnumValue> {
  bool? value;

  @override
  Widget build(BuildContext context) {
    value = value ?? widget.value;
    return CheckboxListTile(
        title: Text(widget.title),
        value: value,
        onChanged: (bool? newValue) {
          if (newValue != null) {
            context.read<SettingsBloc>().add(SettingsPushEvent(
                newSettings: {"setAlertFilterAt": (newValue, widget.index)}));
            setState(() {
              value = newValue;
            });
          }
        });
  }
}
