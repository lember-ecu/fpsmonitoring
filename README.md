# FPS Monitor Package

This Flutter package allows you to monitor the FPS (Frames Per Second) performance of your applications. It is inspired by the [statsfl](https://pub.dev/packages/statsfl) package and provides developers with the opportunity to visually track and improve application performance.

## Features

- Real-time FPS monitoring
- Visualize performance data with charts
- Analyze animation performance
- Identify and improve performance issues
- Easy integration and usage


## Usage

```dart
import 'package:lemberfpsmonitor/lemberfpsmonitor.dart';

void main() {
  runApp(Padding(
    padding: const EdgeInsets.only(top: 40),
    child: FPSMonitor(
      showFPSChart: true,
      align: Alignment.topRight,
      onFPSChanged: (fps) {
        print("fps: $fps");
      },
      child: MaterialApp(
          debugShowCheckedModeBanner: false, home: Scaffold(body: MyApp())),
    ),
  ));
}

## License

- This project is licensed under the MIT License. For more information, please see the [LICENSE](LICENSE) file.

