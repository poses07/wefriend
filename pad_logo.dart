import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

void main() {
  final inputBytes = File('logo.png').readAsBytesSync();
  final decodedImage = img.decodeImage(inputBytes);

  if (decodedImage == null) {
    debugPrint('Failed to decode image');
    return;
  }

  final width = decodedImage.width;
  final height = decodedImage.height;

  // Yeni boyut 2 katı (kenarlardan %50 boşluk)
  final targetSize = (width > height ? width : height) * 2;
  
  // Şeffaf arkaplanlı yeni resim
  final newImage = img.Image(width: targetSize.toInt(), height: targetSize.toInt(), numChannels: 4);
  img.fill(newImage, color: img.ColorRgba8(0, 0, 0, 0));

  // Logoyu merkeze yapıştır
  final dstX = (targetSize - width) ~/ 2;
  final dstY = (targetSize - height) ~/ 2;

  img.compositeImage(newImage, decodedImage, dstX: dstX, dstY: dstY);

  final outputBytes = img.encodePng(newImage);
  File('logo_splash.png').writeAsBytesSync(outputBytes);
  debugPrint('Padded image saved as logo_splash.png');
}