import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_filler_2/FillerReader.dart';

class FillerImage {

  static fromReader(FillerReader reader, ui.ImageDecoderCallback onImageReady) {
    print('getting image size');
    int height = (reader.steps.first.field?.height) ?? 0;
    int width = (reader.steps.first.field?.width) ?? 0;
    print('got image size: $height, $width');
    // int line = width * 4;
    // Uint8List pixels = Uint8List(height * line);
    // for (int i = 0; i < height; i++) {
    //   for (int j = 0; j < line; j++) {
    //     if (j % 4 == 0) {
    //       // pixels[i * line + j] = (i.toDouble() / height * 255).round();
    //       pixels[i * line + j] = 150;
    //     }
    //     if (j % 4 == 1) {
    //       // pixels[i * line + j] = (i.toDouble() / height * 255).round();
    //       pixels[i * line + j] = 0;
    //     }
    //     if (j % 4 == 2) {
    //       // pixels[i * line + j] = (i.toDouble() / height * 255).round();
    //       pixels[i * line + j] = 150;
    //     }
    //     if (j % 4 == 3) {
    //       // pixels[i * line + j] = (i.toDouble() / height * 255).round();
    //       pixels[i * line + j] = 0;
    //     }
    //   }
    // }
    // PixelFormat format = PixelFormat.rgba8888;
    // decodeImageFromPixels(pixels, width, height, format, onImageReady);
    callbackTime(Size(width.toDouble(), height.toDouble()), onImageReady);
  }

  static Future callbackTime(Size size,ui.ImageDecoderCallback onImageReady) async {
    Future<ui.Image> generateImage(Size size) async {
      int width = size.width.ceil();
      int height = size.height.ceil();
      var completer = Completer<ui.Image>();

      Int32List pixels = Int32List(width * height);

      for (var x = 0; x < width; x++) {
        for (var y = 0; y < height; y++) {
          int index = y * width + x;
          pixels[index] = generatePixel(x, y);
        }
      }

      ui.decodeImageFromPixels(
        pixels.buffer.asUint8List(),
        width,
        height,
        ui.PixelFormat.bgra8888,
            (ui.Image img) {
          completer.complete(img);
        },
      );

      return completer.future;
    }
    var image = await generateImage(size);
    onImageReady(image);
  }

  static int generatePixel(int x, int y) {
    return Color.fromRGBO(x, 0, y, 1.0).value;
  }

}