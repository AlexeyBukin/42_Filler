import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:async/async.dart';
import 'package:filler/extensions/string_starts_switch.dart';
import 'package:filler/const.dart' as Const;

typedef FillerUpdateCallback = void Function();

enum FillerReaderState { none, header, step, steps, tail, all, error }

/// Reads input from source and stores parsed data in objects.
///
/// To manually check loading state of widgets loading speed
/// can be slowed down with [debugSlowStepsLoading] constant.
class FillerReader {
  /// Called when [sectionDone] state changes
  final FillerUpdateCallback? onUpdate;

  /// Should be read when [onUpdate] callback is called
  FillerReaderState get sectionDone => _sectionDone;

  /// Should be read when [sectionDone] is [FillerReaderState.header]
  late PlayerPropertyPair names;

  /// Should be read when [sectionDone] is [FillerReaderState.step]
  List<FillerStep> steps = List.empty(growable: true);

  /// Should be read when [sectionDone] is [FillerReaderState.tail]
  late PlayerPropertyPair score;

  /// Should be read when [sectionDone] is [FillerReaderState.error]
  String errorMessage = 'OK';

  /// Main constructor
  FillerReader.fromLinesStream(Stream<String> stream, {this.onUpdate}) {
    _lineStream = stream;
    _subscription =
        _lineStream.listen(_lineStreamListener, onDone: _lineStreamOnDone);
    _sectionDone = FillerReaderState.none;
    score = PlayerPropertyPair('score1', 'score2');
    names = PlayerPropertyPair('player1', 'player2');
  }

  FillerReader.fromCharsStream(Stream<List<int>> input,
      {FillerUpdateCallback? onUpdate})
      : this.fromLinesStream(_charsToLinesStreamTransform(input),
            onUpdate: onUpdate);

  FillerReader.fromFile(String pathToFile, {FillerUpdateCallback? onUpdate})
      : this.fromCharsStream(getFileStream(pathToFile), onUpdate: onUpdate);

  @deprecated

  /// Used only for debug
  FillerReader.fromString(String input, {FillerUpdateCallback? onUpdate})
      : this.fromLinesStream(_splitStringToLines(input), onUpdate: onUpdate);

  /// Starts loading and reading from source
  /// After this call current object is 'alive'
  /// and will trigger [onUpdate] callback
  void start() {
    _loadingOperation = CancelableOperation.fromFuture(_read());
  }

  /// Stops loading and reading of source
  /// After this call current object is 'dead', do not touch it then
  void stop() {
    _loadingOperation?.cancel();
    _subscription.cancel();
  }

  @deprecated
  static const String headerPlayerLineStart = '\$\$\$ exec p0 : ';

  static const String headerPlayer1LineStart = '\$\$\$ exec p1 : ';
  static const String headerPlayer2LineStart = '\$\$\$ exec p2 : ';
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

  // true if _lineStream emitted onDone event
  bool _streamDone = false;

  // Automated state setter with callback notification
  set sectionDone(FillerReaderState completedSection) {
    _sectionDone = completedSection;
    onUpdate?.call();
  }

  // Used to generate error messages
  int _linesRead = 0;

  // Used to stop loading
  CancelableOperation? _loadingOperation;

  // State holder
  late FillerReaderState _sectionDone;

  // Source stream
  late final Stream<String> _lineStream;

  // Source stream subscription
  late final StreamSubscription _subscription;

  // Used as buffer
  // Last line that was read but was not consumed in any operation
  String _lastLine = '';

  // Lets await for next line
  Completer<String?>? _nextLineCompleter;

  // Handles lines overload if they consumed too slow
  Queue<String> _lineQueue = Queue<String>();

  // used to 'await' loading process
  Future? future() {
    return _loadingOperation?.value;
  }

  // main function, handles source parsing
  Future _read() async {
    try {
      await _readHeader();
      sectionDone = FillerReaderState.header;

      await _readSteps();
      sectionDone = FillerReaderState.steps;

      await _readTail();
      sectionDone = FillerReaderState.tail;
      // ???
      sectionDone = FillerReaderState.all;
    } on FillerReadException catch (fre) {
      // debug
      print('WARNING: Caught filler input exception');
      print('Line $_linesRead: \'${fre.message}\'');
      sectionDone = FillerReaderState.error;
      errorMessage = fre.message;
    } catch (e) {
      // debug
      print('WARNING: Caught unknown error');
      print(e);
      sectionDone = FillerReaderState.error;
      errorMessage = 'Unknown Error';
    }
    _subscription.cancel();
    // debug
    print('player1 ${names.player1}');
    print('player2 ${names.player2}');
    print('score1 ${score.player1}');
    print('score2 ${score.player2}');
    print('X char is ' + 'X'.codeUnits.first.toString());
    print('x char is ' + 'x'.codeUnits.first.toString());
    print('O char is ' + 'O'.codeUnits.first.toString());
    print('o char is ' + 'o'.codeUnits.first.toString());
  }

  Future _readHeader() async {
    String? player1name;
    String? player2name;
    final switchPatterns = [
      headerPlayer1LineStart,
      headerPlayer2LineStart,
      stepLineStart
    ];
    while (true) {
      final line = await getNextLine(
          onError: FillerReadException('Unexpected end of header input'));
      switch (line.startsSwitch(values: switchPatterns)) {
        case headerPlayer1LineStart:
          player1name = _getPlayerName(
              line.replaceFirst(headerPlayer1LineStart, '').trim());
          break;
        case headerPlayer2LineStart:
          player2name = _getPlayerName(
              line.replaceFirst(headerPlayer2LineStart, '').trim());
          break;
        case stepLineStart:
          _lastLine = line;
          if (player1name == null || player2name == null) {
            throw FillerReadException(
                'Player ${(player1name == null) ? '1' : '2'} is undefined');
          }
          names = PlayerPropertyPair(player1name, player2name);
          return;
      }
    }
  }

  Future _readSteps() async {
    while (!(_lastLine.startsWith(tailLineStart))) {
      if (Const.debugSlowStepsLoading) {
        await Future.delayed(Const.debugSlowStepsLoadingDelay);
      }
      final field = await _readStepField();
      final piece = await _readStepPiece();
      final info = await _readStepInfo();
      steps.add(FillerStep(field: field, piece: piece, info: info));
      sectionDone = FillerReaderState.step;
    }
  }

  Future<FillerField2d> _readStepField() async {
    final infoList = _lastLine
        .replaceAll(':', '')
        .replaceAll(stepLineStart, '')
        .trim()
        .split(' ');
    if (infoList.length != 2) {
      throw FillerReadException('Cannot read step ${steps.length + 1} info');
    }
    final field = FillerField2d.fromStringValues(
        height: infoList.first,
        width: infoList.last,
        onError: FillerReadException('Cannot read step piece size'));

    var stepLineNumber = 0;
    while (true) {
      final line = await getNextLine(
          onError: FillerReadException('Unexpected end of step field input'));
      stepLineNumber++;
      if (stepLineNumber <= 1) {
        continue;
      }
      if (stepLineNumber > field.height + 1) {
        _lastLine = line;
        return field;
      }
      field.addLine(_stepCharsToIntegers(line.substring(4, null)));
    }
  }

  Future<FillerField2d> _readStepPiece() async {
    final infoList = _lastLine
        .replaceAll(':', '')
        .replaceAll(stepPieceStart, '')
        .trim()
        .split(' ');
    if (infoList.length != 2) {
      throw FillerReadException(
          'Cannot read step ${steps.length + 1} piece info');
    }
    final piece = FillerField2d.fromStringValues(
      height: infoList.first,
      width: infoList.last,
      onError: FillerReadException('Cannot read step piece size'),
    );

    var stepLineNumber = 0;
    while (true) {
      final line = await getNextLine(
          onError: FillerReadException('Unexpected end of step piece input'));
      stepLineNumber++;
      if (stepLineNumber > piece.height) {
        _lastLine = line;
        return piece;
      }
      piece.addLine(_stepCharsToIntegers(line));
    }
  }

  Future _readStepInfo() async {
    final infoList = _lastLine
        .replaceAll(stepLastLineStart, '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll(':', '')
        .replaceAll('[', '')
        .replaceAll(',', '')
        .replaceAll(']', '')
        .trim()
        .split(' ');
    if (infoList.length != 3) {
      throw FillerReadException('Cannot read step ${steps.length + 1} info');
    }
    Function nameGetter = (String pattern) {
      switch (pattern) {
        case 'O':
          return names.player1;
        case 'X':
          return names.player2;
      }
      throw FillerReadException('Cannot read step ${steps.length + 1} player');
    };
    _lastLine = await getNextLine(
        onError: FillerReadException('Unexpected end of step info ending'));
    return FillerStepInfo.fromStringValues(
      player: nameGetter(infoList[0]),
      coordinateX: infoList[1],
      coordinateY: infoList[2],
    );
  }

  Future _readTail() async {
    final first = _lastLine;
    final second = await getNextLine(
        onError: FillerReadException('Unexpected end of tail input'));
    score = PlayerPropertyPair(
      _readTailLine(first, 'O'),
      _readTailLine(second, 'X'),
    );
  }

  String _readTailLine(String line, String pattern) {
    var split = line
        .replaceAll(stepLastLineStart, '')
        .replaceAll('==', '')
        .replaceAll('fin: ', '')
        .trim()
        .split(' ');
    // fast OR aka '||' will not run split.first if length is not 2
    // as stated in https://spec.dart.dev/DartLangSpecDraft.pdf page 166
    if (split.length != 2 || split.first != pattern) {
      throw FillerReadException('Cannot read final score line(s)');
    }
    return split.last;
  }

  String _getPlayerName(String source) {
    if (source.startsWith('[') && source.endsWith(']')) {
      return source.substring(1, source.length - 1);
    }
    throw FillerReadException('Cannot read player name');
  }

  void _lineStreamListener(String newLine) {
    if (_nextLineCompleter != null) {
      _nextLineCompleter!.complete(newLine);
      _nextLineCompleter = null;
    } else {
      _lineQueue.add(newLine);
    }
  }

  void _lineStreamOnDone() {
    _streamDone = true;
    _nextLineCompleter?.complete(null);
    _nextLineCompleter = null;
  }

  Future<String> getNextLine({required FillerReadException onError}) async {
    if (_lineQueue.isNotEmpty) {
      return _lineQueue.removeFirst();
    }
    if (_streamDone) {
      throw onError;
    }
    _nextLineCompleter = Completer<String?>();
    final result = await _nextLineCompleter!.future;
    if (result == null) {
      throw onError;
    }
    return result;
  }

  List<int> _stepCharsToIntegers(String chars) {
    return chars.codeUnits;
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

  static Stream<List<int>> getFileStream(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FillerReadException('File does not exist');
    }
    final startPos = 0;
    final endPos = null;
    return file.openRead(startPos, endPos);
  }
}

class FillerReadException implements Exception {
  String message;

  FillerReadException(this.message);
}

class FillerField2d {
  final List<List<int>> field = List<List<int>>.empty(growable: true);
  late final int height;
  late final int width;

  FillerField2d.fromStringValues({
    required String height,
    required String width,
    required FillerReadException onError,
  }) {
    try {
      this.height = int.parse(height);
      this.width = int.parse(width);
    } on FormatException catch (_) {
      throw onError;
    }
  }

  void addLine(List<int> line) {
    field.add(line);
  }
}

class FillerStep {
  final FillerField2d field;
  final FillerField2d piece;
  final FillerStepInfo info;

  const FillerStep({
    required this.field,
    required this.info,
    required this.piece,
  });
}

class FillerStepInfo {
  final String player;
  late final int coordinateX;
  late final int coordinateY;

  FillerStepInfo.fromStringValues({
    required this.player,
    required String coordinateX,
    required String coordinateY,
  }) {
    this.coordinateX = int.parse(coordinateX);
    this.coordinateY = int.parse(coordinateY);
  }
}

class PlayerPropertyPair {
  final String player1;
  final String player2;

  const PlayerPropertyPair(this.player1, this.player2);
}
