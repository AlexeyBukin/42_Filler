import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:filler/extensions/material_color_creator.dart';
import 'package:filler/filler_reader.dart';
import 'package:filler/filepicker_bridge.dart';
import 'package:filler/extensions/color_harmonies.dart';
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
  var playerSpeed = 1.0;

  // reader replacement
  List<FillerStep> steps = List<FillerStep>.empty(growable: true);
  String player1 = '...';
  String player2 = '...';

  bool get loading => loadingState == LoadingState.loading;

  late FillerReader reader;
  var currentStep = 0;

  // var maxStep = 0;

  // todo rename me
  Future doTheTrick() async {
    // reader.onUpdate = () {
    //   setState(() {
    //     loading = false;
    //     maxStep = reader.steps.length;
    //   });
    // };
    reader.start();
    // await reader.future();
    // reader.steps = reader.steps.map((e) => e == null ? reader.steps.first : e).toList();
    // reader.steps = reader.steps.map((e) => e.field == null ? reader.steps.first : e).toList();
  }

  // CancelableOperation startLoading(FillerReader reader) {
  //   return CancelableOperation.fromFuture(reader.read());
  // }
  //
  // void beginLoading() {
  //   if (loadingState == LoadingState.loading) {
  //     return ;
  //   }
  //   loadingOperation = CancelableOperation.fromFuture(reader.read());
  //
  //   setState(() {
  //     loadingState = LoadingState.loading;
  //     // playerState = PlayerState.playing;
  //   });
  // }

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
    steps = reader.steps
        .map((e) => e.field.width == null ? reader.steps.first : e)
        .toList();
    steps = reader.steps
        .map((e) => e.field.height == null ? reader.steps.first : e)
        .toList();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    reader = FillerReader.fromCharsStream(stdin, onUpdate: onReaderUpdate)
      ..start();
  }

  bool canLoadFile() => loadingState != LoadingState.loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              onPressed: canLoadFile() ? loadLogFile : null,
              icon: Icon(Icons.folder),
              tooltip: canLoadFile()
                  ? 'Load log file'
                  : 'Stop current process to load new one',
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text('Progress: '), progressWidget],
              ),
            ),
            // button(context),
            Text(widget.title),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            buildInfoPanel(),
            buildFieldPanel(),
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
        reader = FillerReader.fromFile(file, onUpdate: onReaderUpdate)..start();
        loadingState = LoadingState.loading;
      });
    }
  }

  Widget buildInfoPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('Player1: ' + player1),
        Text('Player2: ' + player2),
      ],
    );
  }

  Widget buildFieldPanel() {
    var tableWidget = Container(
      // color: Colors.red,
      child: steps.isEmpty
          ? Center(child: Text('Let\'s load some Filler replays!'))
          : buildTable(),
      // padding: EdgeInsets.all(10),
    );
    return Expanded(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: tableWidget,
          ),
          Expanded(
            flex: 1,
            child: buildPiece(),
          )
        ],
      ),
    );
  }

  Widget buildPiece() {
    return Center(
      child: Text('centered text'),
    );
  }

  List<TableRow> fieldTableRowList(List<List<int>> tableData,
      [Color? fieldPrimaryColor]) {
    fieldPrimaryColor ??= Colors.blue;
    final color1 = MaterialColorCreator.create(fieldPrimaryColor);
    final color2 =
        MaterialColorCreator.create(fieldPrimaryColor.complementary());

    final fieldColor = Color.fromARGB(255, 200, 200, 200);
    final rowMapper = (List<int> rowData) => rowData.map((int cellData) {
          // baseColor is assigned as '??=' to constants
          // so it can be safely unwrapped with '!'
          final Color Function(int) getColor = (int cellData) {
            switch (cellData) {
              case FillerReader.player1Old:
                return color1.shade300;
              case FillerReader.player1New:
                return color1;
              case FillerReader.player2Old:
                return color2.shade300;
              case FillerReader.player2New:
                return color2;
              case FillerReader.emptyCell:
                return fieldColor;
              default:
                return Colors.black;
            }
          };
          Color color = getColor(cellData);
          return AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: color,
            ),
          );
        }).toList();
    return tableData
        .map((rowData) => TableRow(children: rowMapper(rowData)))
        .toList();
  }

  Widget buildTable() {
    var step = steps[currentStep].field;
    var width = step.width;
    var height = step.height;
    // double scale = 10;
    // return Container(
    //   padding: EdgeInsets.all(20),
    //   color: Colors.red,
    //   width: scale * width,
    //   height: scale * height,
    //   child: Table(
    //     defaultColumnWidth: const FixedColumnWidth(8),
    //     border: TableBorder.all(),
    //     defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    //     children: fieldTableRowList(step.field),
    //   ),
    // );
    return AspectRatio(
      aspectRatio: width.toDouble() / height.toDouble(),
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(8),
        border: TableBorder.all(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: fieldTableRowList(step.field),
      ),
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

Widget button(context) {
  var currentColor = Colors.blue;
  return RaisedButton(
    elevation: 3.0,
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            titlePadding: const EdgeInsets.all(0.0),
            contentPadding: const EdgeInsets.all(0.0),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (c) {},
                colorPickerWidth: 300.0,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: true,
                displayThumbColor: true,
                showLabel: true,
                paletteType: PaletteType.hsv,
                pickerAreaBorderRadius: const BorderRadius.only(
                  topLeft: const Radius.circular(2.0),
                  topRight: const Radius.circular(2.0),
                ),
              ),
            ),
          );
        },
      );
    },
    child: const Text('Change me'),
    color: Colors.blue,
    textColor: useWhiteForeground(Colors.blue)
        ? const Color(0xffffffff)
        : const Color(0xff000000),
  );
}
