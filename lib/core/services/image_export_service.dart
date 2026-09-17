import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ImageExportService {
  /// Captures a widget attached to [GlobalKey] into a high-resolution PNG byte buffer
  static Future<Uint8List?> captureWidgetToPng(GlobalKey key, {double pixelRatio = 3.0}) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget to image: $e');
      return null;
    }
  }

  /// Downloads or shares the PNG image across Web, Windows Desktop, Android & iOS
  static Future<void> downloadOrShareImage(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        await Share.shareXFiles([
          XFile.fromData(bytes, name: fileName, mimeType: 'image/png'),
        ]);
      }
    } catch (e) {
      debugPrint('Error downloading/sharing image: $e');
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }
}
