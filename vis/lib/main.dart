import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:window_size/window_size.dart';
import 'filler_page.dart';

// cat ../res/logs/abanlin-carli.map00.log.txt | ./build/linux/release/bundle/flutter_filler_2

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Filler Visualizer');
    setWindowMinSize(const Size(640, 480));
    setWindowMaxSize(Size.infinite);
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filler Visualizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FillerPage(title: 'Filler Visualizer by @kcharla'),
    );
  }
}
