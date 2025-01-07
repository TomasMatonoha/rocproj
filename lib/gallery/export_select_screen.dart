import 'dart:io';

import '../processing/image_processing.dart' as imgproc;
import '../processing/to_pdf.dart' as to_pdf;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

Directory get userHome => Directory(Platform.isLinux || Platform.isMacOS
    ? Platform.environment['HOME'] ??
        (throw StateError('HOME not defined in environment.'))
    : Platform.isWindows
        ? Platform.environment['USERPROFILE'] ??
            (throw StateError('USERPROFILE not defined in environment.'))
        : Platform.isAndroid
            ? '/storage/emulated/0'
            : throw UnsupportedError(
                'userHome is not supported on ${Platform.operatingSystem}.'));

class ExportSelectScreen extends StatelessWidget {
  final List<File> selectedPhotos;
  final imgproc.ImageProcessor imageProcessor = imgproc.ImageProcessor();
  final imgproc.Ocr ocr = imgproc.Ocr();
  final to_pdf.TextToPdfConverter textToPdf = to_pdf.TextToPdfConverter();
  final Logger logger = Logger();
  ExportSelectScreen({super.key, required this.selectedPhotos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Ebook Type'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Handle EPUB button press
              },
              child: Text('EPUB'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Handle PDF button press
                logger.i('PDF pressed');
                List<String> pages = [];
                for (File photo in selectedPhotos) {
                  await imageProcessor.loadImage(photo.path);
                  if (!imageProcessor.enforceSizeLimits()) {
                    // image too small
                    await imageProcessor.dispose();
                    continue;
                  }
                  // imageProcessor.optimizeForOCR();
                  // await imageProcessor.save();
                  pages.add(await ocr.extractText(
                      /*imageProcessor.editedOcrFile.path*/ imageProcessor
                          .path));
                }
                await imageProcessor.dispose();
                ocr.dispose();
                final String outputPath =
                    '${userHome.path}/Documents/${DateTime.now().millisecondsSinceEpoch}-${pages.length}.pdf';
                logger.d(pages);
                await textToPdf.convertToPdf(
                    pages: pages, outputPath: outputPath);
              },
              child: Text('PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ExportSelectScreen(selectedPhotos: []),
  ));
}
