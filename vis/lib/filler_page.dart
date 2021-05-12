import 'dart:io';
import 'dart:async';
import 'package:filler/table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:filler/filler_reader.dart';
import 'package:filler/filepicker_bridge.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:math' as math;

enum LoadingState {
  waiting,
  loading,
  finished,
  stopped,
}

enum PlayerState {
  paused,
  playing,
}

class FillerPage extends StatefulWidget {
  FillerPage({Key? key, this.title = 'Title'}) : super(key: key);

  final String title;

  @override
  FillerPageState createState() => FillerPageState();
}

class FillerPageState extends State<FillerPage> {
  var loadingState = LoadingState.waiting;
  var playerState = PlayerState.paused;

  /// Frames per second
  /// When [playerSpeed] == 0 then we should play with the speed of loading
  /// To pause playing use [playerState] with [PlayerState.paused] value
  var playerSpeed = 0.0;

  late List<FillerStep> steps;
  late String player1;
  late String player2;

  bool get loading => loadingState == LoadingState.loading;

  late FillerReader reader;
  var currentStep = 0;

  void onReaderUpdate() {
    progressWidget = Text(reader.sectionDone.toString());
    switch (reader.sectionDone) {
      case FillerReaderState.none:
        // Do nothing
        // progressWidget = Text('state_none')
        break;
      case FillerReaderState.header:
        // TODO: Update score
        setState(() {
          //TODO refactor
          player1 = reader.names.player1;
          player2 = reader.names.player2;
          progressWidget = Text('Header is loaded');
        });
        break;
      case FillerReaderState.step:
        onReaderUpdateStep();
        break;
      case FillerReaderState.steps:
        setState(() {
          progressWidget = Text('Steps are loaded');
        });
        break;
      case FillerReaderState.tail:
        // TODO: Update score
        break;
      case FillerReaderState.all:
        setState(() {
          loadingState = LoadingState.finished;
          progressWidget = Text('Loading done!');
        });
        break;
      case FillerReaderState.error:
        setState(() {
          loadingState = LoadingState.stopped;
          progressWidget = Text('Error occurred while loading');
        });
        break;
    }
  }

  void onReaderUpdateStep() {
    steps = reader.steps;
    setState(() {});
  }

  void clear() {
    steps = List<FillerStep>.empty(growable: false);
    currentStep = 0;
    player1 = '...';
    player2 = '...';
    playerState = PlayerState.paused;
    playerSpeed = 0.0;
  }

  @override
  void initState() {
    super.initState();
    clear();
    reader = FillerReader.fromCharsStream(stdin, onUpdate: onReaderUpdate)
      ..start();
  }

  bool canLoadFile() => loadingState != LoadingState.loading;

  void progressButtonStop() {
    setState(() {
      reader.stop();
      loadingState = LoadingState.stopped;
    });
  }

  Widget progressButton() {
    switch (loadingState) {
      case LoadingState.loading:
        return IconButton(
          onPressed: progressButtonStop,
          icon: Icon(Icons.stop_circle_outlined),
          tooltip: 'Stop',
        );
      case LoadingState.finished:
        return IconButton(
          onPressed: null,
          icon: Icon(Icons.check_circle_outlined),
          tooltip: 'Visualization is ready',
        );
      case LoadingState.stopped:
        return IconButton(
          onPressed: null,
          icon: Icon(Icons.stop_circle_outlined),
          tooltip: 'Loading was stopped',
        );
      case LoadingState.waiting:
        return IconButton(
          onPressed: null,
          icon: Icon(Icons.workspaces_outline),
          tooltip: 'Waiting to load file',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          child: loading ? LinearProgressIndicator() : Container(),
          preferredSize: Size.fromHeight(5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: progressButton(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IconButton(
              onPressed: canLoadFile() ? loadLogFile : null,
              icon: Icon(Icons.folder),
              tooltip: canLoadFile()
                  ? 'Load log file'
                  : 'Stop current process to load new one',
            ),
          ),
        ],
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 10)),
            buildMainPanel(),
            Padding(padding: EdgeInsets.only(top: 10)),
            buildPlayerPanel(),
          ],
        ),
      ),
    );
  }

  Widget progressWidget = Text('here we have progress');

  Widget buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('Progress:'),
        progressWidget,
      ],
    );
  }

  Future loadLogFile() async {
    final String? file = await pickLogFile(context);
    if (file != null) {
      // debug-only
      // print(file);
      setState(() {
        clear();
        reader = FillerReader.fromFile(file, onUpdate: onReaderUpdate)..start();
        loadingState = LoadingState.loading;
      });
    }
  }

  Widget buildInfoPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(player1),
        Padding(padding: EdgeInsets.only(top: 10)),
        Text('VS'),
        Padding(padding: EdgeInsets.only(top: 10)),
        Text(player2),
      ],
    );
  }

  Widget buildMainPanel() {
    var tableWidget = Container(
      // color: Colors.red,
      child: steps.isEmpty
          ? Center(child: Text('Let\'s load some Filler replays!'))
          : InteractiveViewer(
              child: FillerTable(field: steps[currentStep].field),
              maxScale: 2,
            ),
      // padding: EdgeInsets.all(10),
    );
    return Expanded(
      child: Row(
        children: [
          Padding(padding: EdgeInsets.only(left: 10)),
          Expanded(
            flex: 2,
            child: tableWidget,
          ),
          Padding(padding: EdgeInsets.only(left: 10)),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: buildInfoPanel()),
                  Expanded(child: buildPiece()),
                ],
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(left: 10)),
        ],
      ),
    );
  }

  Widget buildPiece() {
    if (steps.isEmpty) {
      return Center(child: Text('Here will be piece preview'));
    }
    return Column(
      children: [
        Text('Next piece:'),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: FillerTable(
                field: steps[currentStep].piece,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget mirrored(Widget child) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: child,
    );
  }

  Widget buildPlayerPanel() {
    var maxStep = steps.length;
    final nextStepIsProhibited = currentStep >= maxStep - 1;
    final backStepIsProhibited = currentStep <= 0;
    bool stepsEmpty = steps.isEmpty;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
                child: Slider(
              value: stepsEmpty ? 0 : (currentStep + 1).toDouble(),
              min: stepsEmpty ? 0 : 1,
              max: stepsEmpty ? 0 : (maxStep).toDouble(),
              divisions: maxStep <= 0 ? null : maxStep,
              label: (currentStep + 1).toString(),
              onChanged: (double value) {
                if (stepsEmpty) {
                  return;
                }
                setState(() {
                  currentStep = value.round() - 1;
                  print('currentStep: $currentStep');
                  print('maxStep: $maxStep');
                });
              },
            )),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                icon: mirrored(Icon(Icons.double_arrow)),
                onPressed: backStepIsProhibited
                    ? null
                    : () {
                        setState(() {
                          currentStep = 0;
                        });
                      }),
            IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: backStepIsProhibited
                    ? null
                    : () {
                        setState(() {
                          currentStep--;
                        });
                      }),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                  '${stepsEmpty ? 0 : currentStep + 1} / ${stepsEmpty ? 0 : maxStep}'),
            ),
            IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: nextStepIsProhibited
                    ? null
                    : () {
                        setState(() {
                          currentStep++;
                        });
                      }),
            IconButton(
                icon: Icon(Icons.double_arrow),
                onPressed: nextStepIsProhibited
                    ? null
                    : () {
                        setState(() {
                          currentStep = maxStep - 1;
                        });
                      }),
          ],
        )
      ],
    );
  }
}

// Widget button(context) {
//   var currentColor = Colors.blue;
//   return RaisedButton(
//     elevation: 3.0,
//     onPressed: () {
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             titlePadding: const EdgeInsets.all(0.0),
//             contentPadding: const EdgeInsets.all(0.0),
//             content: SingleChildScrollView(
//               child: ColorPicker(
//                 pickerColor: currentColor,
//                 onColorChanged: (c) {},
//                 colorPickerWidth: 300.0,
//                 pickerAreaHeightPercent: 0.7,
//                 enableAlpha: true,
//                 displayThumbColor: true,
//                 showLabel: true,
//                 paletteType: PaletteType.hsv,
//                 pickerAreaBorderRadius: const BorderRadius.only(
//                   topLeft: const Radius.circular(2.0),
//                   topRight: const Radius.circular(2.0),
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//     child: const Text('Change me'),
//     color: Colors.blue,
//     textColor: useWhiteForeground(Colors.blue)
//         ? const Color(0xffffffff)
//         : const Color(0xff000000),
//   );
// }
