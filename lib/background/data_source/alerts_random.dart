/*
 * SPDX-FileCopyrightText: 2024 okaycode.dev LLC and Open Alert Viewer authors
 *
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';

import '../../alerts/model/alerts.dart';

class RandomAlerts extends AlertSource {
  RandomAlerts(
      {required super.id,
      required super.name,
      required super.type,
      required super.baseURL,
      required super.path,
      required super.username,
      required super.password})
      : _randomSeed = Random(DateTime.now().microsecondsSinceEpoch),
        _alerts = [];

  final Random _randomSeed;
  List<Alert> _alerts;

  @override
  Future<List<Alert>> fetchAlerts() async {
    List<Alert> nextAlerts = [];
    int count = 20 + _randomSeed.nextInt(20);
    for (int i = 0; i < count; i++) {
      nextAlerts.add(Alert(
          source: id,
          kind: AlertType
              .values[_randomSeed.nextInt(AlertType.values.length - 1)],
          hostname: "example.com",
          service: "fizz buzz",
          message: "foo bar baz",
          url: "https://example.com",
          age: Duration(seconds: _randomSeed.nextInt(60 * 10))));
    }
    // simulate network timeout
    await Future.delayed(Duration(milliseconds: _randomSeed.nextInt(4000)));
    _alerts = nextAlerts;
    return _alerts;
  }
}
