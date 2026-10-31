import 'package:flutter/material.dart';

void main() => runApp(const GeoAlertApp());

class GeoAlertApp extends StatelessWidget {
  const GeoAlertApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'Geo Alert',
    home: Scaffold(body: Center(child: Text('Geo Alert'))),
  );
}
