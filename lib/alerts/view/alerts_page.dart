/*
 * SPDX-FileCopyrightText: 2024 Andrew Engelbrecht <andrew@sourceflow.dev>
 *
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../navigation/bloc/navigation_bloc.dart';
import '../../navigation/bloc/navigation_event.dart';
import '../../app/data_repository/settings_repository.dart';
import '../../app/view/app_view_elements.dart';
import '../../notifications/bloc/notification_bloc.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../bloc/alerts_event.dart';
import '../bloc/alerts_state.dart';
import '../bloc/alerts_bloc.dart';
import '../bloc/timer_bloc.dart';
import 'alerts.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.title});

  final String title;

  static Route<void> route({required title}) {
    return MaterialPageRoute<void>(builder: (_) => AlertsPage(title: title));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AlertsHeader(title: title), body: const AlertsList());
  }
}

class AlertsHeader extends StatelessWidget implements PreferredSizeWidget {
  const AlertsHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    var settings = context.read<SettingsRepo>();
    Widget notificationsStatusWidget;
    return BlocBuilder<SettingsBloc, SettingsState>(builder: (context, state) {
      if (!settings.notificationsEnabled) {
        notificationsStatusWidget = HeaderButton(
            icon: Icons.notifications_off,
            onPressed: () =>
                context.read<NavBloc>().add(OpenGeneralSettingsPageEvent()));
      } else {
        notificationsStatusWidget = Container();
      }
      return AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          leading: HeaderButton(
              icon: Icons.menu,
              onPressed: () =>
                  context.read<NavBloc>().add(OpenSettingsPageEvent())),
          title: Text(title),
          actions: [
            notificationsStatusWidget,
            HeaderButton(
                icon: Icons.refresh,
                onPressed: () {
                  context.read<NotificationBloc>().add(UpdateLastCheckTime());
                  context
                      .read<AlertsBloc>()
                      .add(FetchAlerts(forceRefreshNow: true));
                })
          ]);
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AlertsList extends StatefulWidget {
  const AlertsList({super.key});

  @override
  State<AlertsList> createState() => _AlertsListState();
}

class _AlertsListState extends State<AlertsList> with WidgetsBindingObserver {
  _AlertsListState() : refreshKey = GlobalKey<RefreshIndicatorState>();

  final GlobalKey<RefreshIndicatorState> refreshKey;
  late SettingsRepo _settings;

  @override
  void initState() {
    super.initState();
    _settings = context.read<SettingsRepo>();
    WidgetsBinding.instance.addObserver(this);
    context.read<NotificationBloc>().add(UpdateLastCheckTime());
    context.read<NotificationBloc>().add(
        RequestAndEnableNotificationEvent(askAgain: false, callback: () {}));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      context.read<NotificationBloc>().add(UpdateLastCheckTime());
    }
    if (state == AppLifecycleState.resumed && _settings.notificationsEnabled) {
      context.read<NotificationBloc>().add(
          RequestAndEnableNotificationEvent(askAgain: false, callback: () {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.read<TimerBloc>().add(StartTimerIntervalEvent(callback: (timer) {
      context.read<AlertsBloc>().add(FetchAlerts(forceRefreshNow: true));
    }));
    return BlocBuilder<AlertsBloc, AlertState>(builder: (context, state) {
      List<Widget> alertWidgets = [];
      Widget child;
      bool? isFetching;
      if (state is AlertsFetching) {
        isFetching = true;
        refreshKey.currentState?.show();
      } else if (state is AlertsFetching) {
        isFetching = false;
      }
      if (state.sources.isEmpty) {
        child = const EmptyPane(
            icon: Icons.login, text: "Please configure an account");
      } else if (state.alerts.isEmpty) {
        child = const EmptyPane(icon: Icons.check, text: "No alerts here!");
      } else {
        for (var alert in state.alerts) {
          alertWidgets.add(AlertWidget(alert: alert));
        }
        child = ListView(children: alertWidgets);
      }
      return RefreshIndicator(
          onRefresh: () async {
            if (isFetching != true) {
              context
                  .read<AlertsBloc>()
                  .add(FetchAlerts(forceRefreshNow: true));
            }
            await context.read<AlertsBloc>().stream.firstWhere(
                  (state) => state is! AlertsFetching,
                );
          },
          key: refreshKey,
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          child: child);
    });
  }
}

class EmptyPane extends StatelessWidget {
  const EmptyPane({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme.onSurface;
    return Center(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(icon, size: 100, color: color),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(fontSize: 20, color: color))
        ]));
  }
}
