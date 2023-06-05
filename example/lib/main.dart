import 'package:flutter/material.dart';
import 'package:lemberfpsmonitor/lemberfpsmonitor.dart';

void main() {
  //Enable this to measure your repaint regions
  //debugRepaintRainbowEnabled = true;
  runApp(Padding(
    padding: const EdgeInsets.only(top: 40),
    child: FPSMonitor(
      showFPSChart: false,
      align: Alignment.topRight,
      onFPSChanged: (fps) {
        print("fps: $fps");
      },
      child: MaterialApp(
          debugShowCheckedModeBanner: false, home: Scaffold(body: MyApp())),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ListView.builder(itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 100,
          color: Colors.red,
        ),
      );
    }));
  }
}
