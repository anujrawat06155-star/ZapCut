import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZapCut'),
      ),
      body: const Center(
        child: Text(
          'ZapCut Video Editor',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
