import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtual_tablet/src/screens/start.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);

    return MaterialApp(
      title: "Virtual Tablet",
      home: Scaffold(
        body: StartScreen(),
      ),
    );
  }
}
