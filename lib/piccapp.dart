import 'package:flutter/material.dart';

import 'homepage.dart';

class PiccApp extends StatelessWidget {
  const PiccApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Picture App v0.0.4',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}
