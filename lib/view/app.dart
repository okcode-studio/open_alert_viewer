import 'package:flutter/material.dart';

import '../model/alerts.dart';
import 'alerts.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Alert Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: AlertsPage(title: 'Open Alert Viewer', sources: [RandomAlerts()]),
    );
  }
}
