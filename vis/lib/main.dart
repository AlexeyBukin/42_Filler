import 'dart:io';
import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:filler/filler_reader.dart';
import 'package:filler/filepicker_bridge.dart';
import 'package:filler/extensions/color_harmonies.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:math' as math;

import 'package:window_size/window_size.dart';

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
      home: MyHomePage(title: 'Filler Visualizer by @kcharla'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title = 'Title'}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CancelableOperation? loadingOperation;
  bool loading = true;
  var reader = FillerReader.fromCharsStream(stdin);
  var currentStep = 0;
  var maxStep = 0;

  // todo rename me
  Future doTheTrick() async {
    reader.onUpdate = () {
      setState(() {
        loading = false;
        maxStep = reader.steps.length;
      });
    };
    await reader.read();
    // reader.steps = reader.steps.map((e) => e == null ? reader.steps.first : e).toList();
    // reader.steps = reader.steps.map((e) => e.field == null ? reader.steps.first : e).toList();
    reader.steps = reader.steps
        .map((e) => e.field?.width == null ? reader.steps.first : e)
        .toList();
    reader.steps = reader.steps
        .map((e) => e.field?.height == null ? reader.steps.first : e)
        .toList();
    print(reader.steps.map((step) => step.field?.width).toList());
  }

  @override
  void initState() {
    super.initState();
    doTheTrick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              onPressed: loadLogFile,
              icon: Icon(Icons.folder),
              tooltip: 'Load log file',
            ),
            button(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Align(
                  child: Text(widget.title),
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // buildInfoPanel(),
            buildFieldPanel(),
            buildPlayerPanel(),
          ],
        ),
      ),
    );
  }

  Future loadLogFile() async {
    final String? file = await pickLogFile(context);
    if (file != null) {
      print(file);
      setState(() {
        loading = true;
      });
      reader = FillerReader.fromFile(file);
      doTheTrick();
      // todo open and load file
    }
  }

  Widget buildInfoPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('Player1: ' + (loading ? '...' : reader.player1!)),
        Text('Player2: ' + (loading ? '...' : reader.player2!)),
      ],
    );
  }

  Widget buildFieldPanel() {
    var tableWidget = Container(
      // color: Colors.red,
      child: reader.steps.isEmpty
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
    final color1 = createMaterialColor(fieldPrimaryColor);
    final color2 = createMaterialColor(fieldPrimaryColor.complementary());

    final fieldColor = Color.fromARGB(255, 200, 200, 200);
    final rowMapper = (List<int> rowData) =>
        rowData.map((int cellData) {
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
    var step = reader.steps[currentStep].field!;
    var width = step.width!;
    var height = step.height!;
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
    final nextStepIsProhibited = currentStep >= maxStep - 1;
    final backStepIsProhibited = currentStep <= 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
                child: Slider(
                  value: loading ? 0 : (currentStep + 1).toDouble(),
                  min: loading ? 0 : 1,
                  max: loading ? 0 : (maxStep).toDouble(),
                  divisions: maxStep <= 0 ? null : maxStep,
                  label: (currentStep + 1).toString(),
                  onChanged: (double value) {
                    setState(() {
                      currentStep = value.round() - 1;
                      print('currentStep: $currentStep');
                      print('maxStep: $maxStep');
                      print('arr: ${reader.steps.length}');
                      // _currentSliderValue = value;
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
                  '${loading ? 0 : currentStep + 1} / ${loading
                      ? 0
                      : maxStep}'),
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
                onColorChanged: (c){},
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

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  var swatch = Map<int, Color>();
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(color.value, swatch);
}