import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../processing/image_processing.dart' as improc;
import '../processing/to_pdf.dart' as to_pdf;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

Directory get userHome => Directory(Platform.isLinux || Platform.isMacOS ? Platform.environment['HOME'] ?? (throw StateError('HOME not defined in environment.')) : Platform.isWindows ? Platform.environment['USERPROFILE'] ?? (throw StateError('USERPROFILE not defined in environment.')) : Platform.isAndroid ? '/sdcard' : throw UnsupportedError('userHome is not supported on ${Platform.operatingSystem}.'));

class TypeSelectScreen extends StatelessWidget {
  final List<File> selectedPhotos;
  final improc.ImageProcessor imageProcessor = improc.ImageProcessor();
  final improc.Ocr ocr = improc.Ocr();
  final to_pdf.TextToPdfConverter textToPdf = to_pdf.TextToPdfConverter();
  final Logger logger = Logger();
  TypeSelectScreen({super.key, required this.selectedPhotos});

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
                onPressed: () async{
                // Handle PDF button press
                logger.i('PDF pressed');
                List<String> pages = [];
                for (File photo in selectedPhotos) {
                  await imageProcessor.loadImage(photo.path);
                  if (!imageProcessor.enforceSizeLimits()) {
                  // image too small
                  continue;
                  }
                  imageProcessor.optimizeForOCR();
                  await imageProcessor.save();
                  pages.add(await ocr.extractText(photo.path));
                }
                ocr.dispose();
                final String outputPath = '${userHome.path}/Documents/${DateTime.now().millisecondsSinceEpoch}-${pages.length}.pdf';
                logger.i('Output path: $outputPath');
                textToPdf.convertToPdf(pages: pages, outputPath: outputPath);
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
    home: TypeSelectScreen(selectedPhotos: []),
  ));
}