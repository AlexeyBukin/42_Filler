import 'package:flutter/material.dart';
import 'package:filler/extensions/color_harmonies.dart';
import 'package:filler/filler_reader.dart';
import 'package:filler/extensions/material_color_creator.dart';
import 'package:flutter/rendering.dart';

class FillerTable extends StatelessWidget {
  final FillerField2d field;
  final double? cellSize;
  final Color fieldPrimaryColor;

  const FillerTable({
    required this.field,
    this.cellSize,
    this.fieldPrimaryColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (cellSize != null) {
      return Table(
        defaultColumnWidth: FixedColumnWidth(cellSize!),
        border: TableBorder.all(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: fieldTableRowList(field.field),
      );
    }
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(10),
      child: AspectRatio(
        aspectRatio: field.width.toDouble() / field.height.toDouble(),
        child: Table(
          // defaultColumnWidth: const FixedColumnWidth(8),
          border: TableBorder.all(),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: fieldTableRowList(field.field),
        ),
      ),
    );
  }

  List<TableRow> fieldTableRowList(List<List<int>> tableData) {
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
              case FillerReader.pieceCell:
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
          if (cellSize != null) {
            return Container(
              height: cellSize,
              color: color,
            );
          } else {
            return AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: color,
              ),
            );
          }
        }).toList();
    return tableData
        .map((rowData) => TableRow(children: rowMapper(rowData)))
        .toList();
  }
}
