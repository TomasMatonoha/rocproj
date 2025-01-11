import 'dart:io';
import '../processing/image_processing.dart' as imgproc;
import '../processing/doc_processing.dart' as docproc;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';
import 'package:file_picker/file_picker.dart';

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

class ExportSelectScreen extends StatefulWidget {
  final List<File> selectedPhotos;
  const ExportSelectScreen({super.key, required this.selectedPhotos});

  @override
  State<ExportSelectScreen> createState() => ExportSelectScreenState();
}

class ExportSelectScreenState extends State<ExportSelectScreen> {
  final imgproc.ImageProcessor iP = imgproc.ImageProcessor();
  final imgproc.Ocr ocr = imgproc.Ocr();
  final docproc.TextToPdfConverter ttPDF = docproc.TextToPdfConverter();
  final docproc.TextToEpubConverter ttEpub = docproc.TextToEpubConverter();
  final logger = Logger();
  bool _loading = false;
  String? _selectedLanguage;

  List<File> get selectedPhotos => widget.selectedPhotos;

  Future<void> _processPdf() async {
    logger.d('PDF pressed');
    final outputPath = await _getUserInputForOutputPath();
    if (outputPath == null || outputPath.isEmpty) {
        // User canceled or didn't provide a valid path
        setState(() {
          _loading = false;
        });
        return;
      }
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
    logger.d(pages.length);
    await ttPDF.convertToPdf(pages: pages, outputPath: outputPath);
    await iP.dispose();
    await ocr.dispose();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _processEpub(String language) async {
    final outputPath = await _getUserInputForOutputPath();
    if (outputPath == null || outputPath.isEmpty) {
        // User canceled or didn't provide a valid path
        setState(() {
          _loading = false;
        });
        return;
      }
    logger.d('Epub pressed with language: $language');
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
    logger.d(pages.length);
    await ttEpub.convertToEpub(
        pages: pages, outputPath: outputPath, language: language);
    await iP.dispose();
    await ocr.dispose();
    setState(() {
      _loading = false;
    });
  }

Future<String?> _getUserInputForOutputPath() async {
    String? outputPath;
    logger.d('User input for output path');
    var result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
      initialDirectory: userHome.path,
    );
    logger.d(result);
    if (result != null) {
      logger.d(result);
      outputPath = result;
    }
    return outputPath;
  }

  Future<bool> _showLanguageSelectionDialog() async {
    bool selected = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Book Language'),
          content: DropdownButton<String>(
            value: _selectedLanguage,
            items: <String>['English', 'Spanish', 'French', 'German']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedLanguage = newValue;
                selected = true;
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
    return selected;
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Ebook Type'),
      ),
      body: Center(
        child: Stack(
          children: [
            if (!_loading)
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _loading = true;
                          });
                          await _processPdf();
                          setState(() {
                            _loading = false;
                          });
                          // select where to save
                        },
                        child: Text('PDF')),
                    ElevatedButton(
                        onPressed: () async {
                          if(await _showLanguageSelectionDialog()){
                            setState(() {
                              _loading = true;
                            });
                            await _processEpub(_selectedLanguage!);
                            setState(() {
                              _loading = false;
                            });
                          }
                        },
                        child: Text('EPUB')),
                  ]),
            if (_loading)
              Center(
                child: CircularProgressIndicator(),
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
