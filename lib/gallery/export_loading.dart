import 'dart:io';

import '../processing/image_processing.dart' as imgproc;
import '../processing/doc_processing.dart' as docproc;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;


class ExportLoadingScreen extends StatefulWidget {
  final List<File> selectedPhotos;
  final String outputPath;
  final String fileType;
  const ExportLoadingScreen({super.key, required this.selectedPhotos, required this.outputPath, required this.fileType});

  @override
  State<ExportLoadingScreen> createState() => ExportLoadingScreenState();
}

class ExportLoadingScreenState extends State<ExportLoadingScreen> {
  final imgproc.ImageProcessor iP = imgproc.ImageProcessor();
  final imgproc.Ocr ocr = imgproc.Ocr();

  List<File> get selectedPhotos => widget.selectedPhotos;
  String get outputPath => widget.outputPath;
  String get filetype => widget.fileType;

  Future<void> _processPdf() async {
    List<String> pages = [];
    for (File photo in selectedPhotos) {
      await iP.loadImage(photo.path);
      if (!iP.enforceSizeLimits()) {
        // image too small
        await iP.dispose();
        continue;
      }
      iP.optimizeForOCR();
      final outputPath =
          '${p.dirname(photo.path)}/Optimized/${p.basename(photo.path)}';
      await iP.save(outputPath);
      pages.add(await ocr.extractText(outputPath));
    }
    var pdf = docproc.TextToPdfConverter(bookContent: pages, outputPath: outputPath);
    await pdf.convertToPdf();
    await iP.dispose();
    await ocr.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            FutureBuilder(
                future: () {
                  switch (filetype) {
                    case 'PDF':
                      return _processPdf();
                    case 'EPUB':
                    // TODO: implement EPUB processing
                    // return _processEPUB();
                    return null;
                    default:
                      return null;
                  }
                }(),
                builder: (context, snapshot) { 
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.connectionState == ConnectionState.done) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(seconds: 2), () {
                          context.mounted ? Navigator.pop(context) : null;
                      });
                    });
                    return Center(
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 100,
                      ),
                    )
                  ;
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(seconds: 2), () {
                          context.mounted ? Navigator.pop(context) : null;
                      });
                    });
                    return Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 100,
                      ),
                    );
                  }
                 },
                ),
      ),
      );
  }
}

void main() {
  runApp(MaterialApp(
    home: ExportLoadingScreen(selectedPhotos: [], outputPath: '', fileType: ''),
  ));
}
