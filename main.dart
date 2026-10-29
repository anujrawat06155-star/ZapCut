import 'package:flutter/material.dart';

void main() {
  runApp(const ZapCutApp());
}

class ZapCutApp extends StatelessWidget {
  const ZapCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZapCut',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ZapCutHomeScreen(),
    );
  }
}

class ZapCutHomeScreen extends StatelessWidget {
  const ZapCutHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZapCut Video Editor'),
      ),
      body: const Center(
        child: Text(
          'Welcome to ZapCut!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
