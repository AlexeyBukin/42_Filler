// @dart=2.9

import 'dart:io';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

Future<String> pickLogFile(BuildContext context) async {
  return await FilesystemPicker.open(
    title: 'Load filler log file',
    context: context,
    initDirectory: Directory.current,
    rootDirectory: Directory(path.rootPrefix('')),
    fsType: FilesystemType.file,
    folderIconColor: Theme.of(context).primaryColor,
    fileTileSelectMode: FileTileSelectMode.wholeTile,
  );
}
