/*
 * SPDX-FileCopyrightText: 2024 Andrew Engelbrecht <andrew@sourceflow.dev>
 *
 * SPDX-License-Identifier: MIT
 */

import '../model/alerts.dart';

class AllAlerts {
  AllAlerts() {
    _alertSources = {};
    _alerts = [];
    _lastFetch = DateTime.utc(1970);
  }

  late Set<AlertSource> _alertSources;
  late List<Alert> _alerts;
  late DateTime _lastFetch;

  void addSources({required List<AlertSource> sources}) {
    _alertSources.addAll(sources);
  }

  void removeSource({required AlertSource source}) {
    _alertSources.remove(source);
  }

  Future<List<Alert>> fetch({required Duration maxCacheAge}) async {
    if (maxCacheAge.compareTo(DateTime.now().difference(_lastFetch)) > 0) {
      return _alerts;
    }

    List<Alert> newAlerts = [];
    List<List<Alert>> fetched = [];
    List<Future<List<Alert>>> incoming = [];

    for (var source in _alertSources) {
      incoming.add(source.fetchAlerts());
    }

    fetched = await Future.wait(incoming);
    for (var result in fetched) {
      newAlerts.addAll(result);
    }

    newAlerts.sort((a, b) => a.age.compareTo(b.age));
    _alerts = newAlerts;

    _lastFetch = DateTime.now();
    return _alerts;
  }
}
