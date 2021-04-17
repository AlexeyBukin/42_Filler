import 'dart:async';
import 'dart:io';

typedef FillerUpdateCallback = void Function();

enum FillerReaderState { header, steps, tail, done, error }

// Main class to process Filler game
class FillerReader {
  int linesRead = 0;

  late final Stream<String> lineStream;

  // late final StreamSubscription<String> subscription;

  String? player1;
  String? player2;

  String? score1;
  String? score2;

  bool headerDone = true;
  bool stepsDone = true;
  bool allDone = true;

  static const String headerPlayerLineStart = '\$\$\$ exec p0 : ';
  static const String stepLineStart = 'Plateau';
  static const String stepPieceStart = 'Piece';
  static const String stepLastLineStart = '<got ';
  static const String tailLineStart = '==';

  static const pieceCell = 42; // '*'
  static const emptyCell = 46; // '.'
  static const player1Old = 88; // 'X'
  static const player1New = 120; // 'x'
  static const player2Old = 79; // 'O'
  static const player2New = 111; // 'o'

  String _lastLine = '';
  List<FillerStep> steps = List.empty(growable: true);

  FillerUpdateCallback? onUpdate;

  FillerReader.fromLinesStream(Stream<String> stream) {
    lineStream = stream.asBroadcastStream();
  }

  FillerReader.fromString(String input)
      : this.fromLinesStream(_splitStringToLines(input));

  FillerReader.fromCharsStream(Stream<List<int>> input)
      : this.fromLinesStream(_charsToLinesStreamTransform(input));

  FillerReader.fromFile(String pathToFile)
      : this.fromCharsStream(getFileStream(pathToFile));

  static Stream<List<int>> getFileStream(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FillerReadException('File does not exist');
    }
    final startPos = 0;
    final endPos = null;
    return file.openRead(startPos, endPos);
  }

  void defaultOnDone(FillerReader reader) {
    print(reader.player1);
    print(reader.player2);
  }

  Future read() async {
    try {
      await _readHeader();
      headerDone = true;
      onUpdate?.call();
      await _readSteps();
      stepsDone = true;
      onUpdate?.call();
      await _readTail();
      allDone = true;
      onUpdate?.call();
      if (player1 == null || player2 == null) {
        throw FillerReadException(
            'Player ${(player1 == null) ? '1' : '2'} is undefined');
      }
    } on FillerReadException catch (fre) {
      print('WARNING: Caught filler input exception');
      print('Line $linesRead: \'${fre.message}\'');
    } catch (e) {
      print(e);
    }
    print('player1 $player1');
    print('player2 $player2');
    print('score1 $score1');
    print('score2 $score2');
    print('X char is ' + 'X'.codeUnits.first.toString());
    print('x char is ' + 'x'.codeUnits.first.toString());
    print('O char is ' + 'O'.codeUnits.first.toString());
    print('o char is ' + 'o'.codeUnits.first.toString());
  }

  Future _readHeader() async {
    final player1match = headerPlayerLineStart.replaceFirst('0', '1');
    final player2match = headerPlayerLineStart.replaceFirst('0', '2');

    while (true) {
      var line = await getOneLine();
      if (line == null) {
        throw FillerReadException('Unexpected end of header input');
      }

      if (line.startsWith(stepLineStart)) {
        _lastLine = line;
        return;
      }

      if (line.startsWith(player1match)) {
        final name = _getPlayerName(line.replaceFirst(player1match, '').trim());
        if (name == null) {
          throw FillerReadException('Cannot read player name');
        }
        player1 = name;
      } else if (line.startsWith(player2match)) {
        final name = _getPlayerName(line.replaceFirst(player2match, '').trim());
        if (name == null) {
          throw FillerReadException('Cannot read player name');
        }
        player2 = name;
      }
    }
  }

  String? _getPlayerName(String source) {
    if (source.startsWith('[') && source.endsWith(']')) {
      return source.substring(1, source.length - 1);
    }
    return null;
  }

  Future<String?> getOneLine() async {
    await for (var line in lineStream) {
      linesRead++;
      return line;
    }
    return null;
  }

  Future _readSteps() async {
    while (!(_lastLine.startsWith(tailLineStart))) {
      await _readStep();
      onUpdate?.call();
    }
  }

  Future _readStep() async {
    var step = FillerStep();
    step.field = _lastLine.startsWith(stepPieceStart)
        ? FillerField2d()
        : await _readStepField();
    step.piece = await _readStepPiece();
    step.info = await _readStepInfo();
    steps.add(step);
  }

  Future<FillerField2d> _readStepField() async {
    final fieldInfoLine = _lastLine;
    var field = FillerField2d();

    var info = fieldInfoLine
        .replaceAll(':', '')
        .replaceAll(stepLineStart, '')
        .trim()
        .split(' ');

    if (info.length != 2) {
      throw FillerReadException('Cannot read step ${steps.length + 1} info');
    }

    field.height = int.tryParse(info.first);
    field.width = int.tryParse(info.last);

    if (field.height == null || field.width == null) {
      throw FillerReadException('Cannot read step size');
    }

    var stepLineNumber = 0;

    while (true) {
      var line = await getOneLine();
      if (line == null) {
        throw FillerReadException('Unexpected end of step field input');
      }
      stepLineNumber++;
      if (stepLineNumber <= 1) {
        continue;
      }
      if (stepLineNumber > field.height! + 1) {
        _lastLine = line;
        stepsDone = true;
        return field;
      }
      field.addLine(_stepCharsToIntegers(line.substring(4, null)));
    }
  }

  List<int> _stepCharsToIntegers(String chars) {
    return chars.codeUnits;
  }

  // TODO merge with stepField
  Future<FillerField2d> _readStepPiece() async {
    final pieceInfoLine = _lastLine;

    var piece = FillerField2d();
    var info = pieceInfoLine
        .replaceAll(':', '')
        .replaceAll(stepPieceStart, '')
        .trim()
        .split(' ');

    if (info.length != 2) {
      throw FillerReadException(
          'Cannot read step ${steps.length + 1} piece info');
    }

    piece.height = int.tryParse(info.first);
    piece.width = int.tryParse(info.last);

    if (piece.height == null || piece.width == null) {
      throw FillerReadException('Cannot read step piece size');
    }

    var stepLineNumber = 0;

    while (true) {
      var line = await getOneLine();
      if (line == null) {
        throw FillerReadException('Unexpected end of step piece input');
      }
      stepLineNumber++;
      if (stepLineNumber > piece.height!) {
        _lastLine = line;
        return piece;
      }
      piece.addLine(_stepCharsToIntegers(line));
    }
  }

  Future _readStepInfo() async {
    var infoLine = _lastLine;
    var stepInfo = FillerStepInfo();

    var info = infoLine
        .replaceAll(stepLastLineStart, '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll(':', '')
        .replaceAll('[', '')
        .replaceAll(',', '')
        .replaceAll(']', '')
        .trim()
        .split(' ');
    if (info.length != 3) {
      throw FillerReadException('Cannot read step ${steps.length + 1} info');
    }

    switch (info.first) {
      case 'O':
        stepInfo.player = player1;
        break;
      case 'X':
        stepInfo.player = player2;
        break;
      default:
        throw FillerReadException('Cannot read step player');
    }

    stepInfo.coordinateY = int.tryParse(info[1]);
    stepInfo.coordinateX = int.tryParse(info[2]);

    if (stepInfo.coordinateY == null || stepInfo.coordinateX == null) {
      throw FillerReadException('Cannot read step info coordinates');
    }

    var line = await getOneLine();
    if (line == null) {
      throw FillerReadException('Unexpected end of step info ending');
    }
    _lastLine = line;
    return stepInfo;
  }

  Future _readTail() async {
    var first = _lastLine;
    var second;

    var line = await getOneLine();
    if (line == null) {
      throw FillerReadException('Unexpected end of tail input');
    }
    second = line;
    _readTailLines(first, second);
    allDone = true;
  }

  void _readTailLines(String first, String second) {
    Function set = (String line) {
      var split = line
          .replaceAll(stepLastLineStart, '')
          .replaceAll('==', '')
          .replaceAll('fin: ', '')
          .trim()
          .split(' ');
      if (split.length != 2) {
        throw FillerReadException('Cannot read final score lines');
      }
      switch (split.first) {
        case 'O':
          score1 = split.last;
          break;
        case 'X':
          score2 = split.last;
          break;
        default:
          throw FillerReadException('Cannot read final score player');
      }
    };
    set(first);
    set(second);
    if (score1 == null || score2 == null) {
      throw FillerReadException(
          'Score ${score1 == null ? '1' : '2'} is undefined');
    }
  }

  static Stream<String> _splitStringToLines(String source) async* {
    for (var line in source.split('\n')) {
      yield line;
    }
  }

  static Stream<String> _charsToLinesStreamTransform(
      Stream<List<int>> charStream) async* {
    const CR = 13;
    const LF = 10;
    var line = List<int>.empty(growable: true);
    await for (var list in charStream) {
      for (var char in list) {
        if (char == LF) {
          if (line.isNotEmpty && line.last == CR) {
            line.removeLast();
          }
          yield String.fromCharCodes(line);
          line.clear();
        } else {
          line.add(char);
        }
      }
    }
  }
}

class FillerReadException implements Exception {
  String message;

  FillerReadException(this.message);
}

class FillerField2d {
  List<List<int>> field = List.empty(growable: true);
  int? height;
  int? width;

  FillerField2d();

  void addLine(List<int> line) {
    field.add(line);
  }

  List<int> operator [](index) {
    return field[index];
  }
}

class FillerStep {
  FillerField2d? field;
  FillerField2d? piece;
  FillerStepInfo? info;

  FillerStep();
}

class FillerStepInfo {
  String? player;
  int? coordinateX;
  int? coordinateY;

  FillerStepInfo();
}
