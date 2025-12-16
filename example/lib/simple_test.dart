import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SimpleTest(),
    );
  }
}

class SimpleTest extends StatelessWidget {
  const SimpleTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Test')),
      body: const Center(
        child: Text(
          'App Running Successfully!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
