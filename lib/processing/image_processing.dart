import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:path/path.dart' as p;


class ImageProcessor {
  static const int _maxResolution = 1080 * 1080;
  static const int _minResolution = 500 * 500;
  late img.Image? _image;
  late String path;

  Future<void> loadImage(final String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    _image = img.decodeImage(bytes);
    path = imagePath;
  }

  // resizes, if too small returns false
  bool enforceSizeLimits() {
    final int resolution = _image!.width * _image!.height;
    final double scale = _maxResolution / resolution;
    final desiredWidth = (_image!.width * scale).round();
    final desiredHeight = (_image!.height * scale).round();

    // image too large - resize for less memory usage
    if (resolution > _maxResolution) {
      _image =
          img.copyResize(_image!, width: desiredWidth, height: desiredHeight);
      //logger.d('IMGPROC: Resized image to $desiredWidth x $desiredHeight');
      return true;
    }
    // image too small - reject
    if (resolution < _minResolution) {
      //logger.e('IMGPROC: Image $path too small');
      return false;
    }
    // image was within limits already
    //logger.d('IMGPROC: Image $image within limits : $resolution | $minResolution <-> $maxResolution');

    return true;
  }

  void convertToGrayscale() {
    _image = img.grayscale(_image!);
  }

  void reduceNoise() {
    _image = img.gaussianBlur(_image!, radius: 1);
  }

  void applyThreshold(int threshold) {
    _image = img.luminanceThreshold(_image!, threshold: threshold);
  }

  void adjustBrightness(double factor) {
    _image = img.adjustColor(
      _image!,
      brightness: factor,
    );
  }

  void adjustContrast(double factor) {
    _image = img.adjustColor(
      _image!,
      contrast: factor,
    );
  }

  void optimizeForOCR() {
    if (!enforceSizeLimits()) return;
    adjustBrightness(0.5);
    adjustContrast(0.5);
    reduceNoise();
    convertToGrayscale();
    reduceNoise();
    //logger.d('IMPROC: Optimized image for OCR');
  }

  Future<void> save(final String path) async {
/*     final dirname = p.dirname(path);
    final filename = p.basename(path);

    await Directory(dirname).create(); */
      if (!Directory(p.dirname(path)).existsSync()) {
        Directory(p.dirname(path)).createSync(recursive: true);
      }
      var imgprocSavedFile = File(path);
      final bytes = img.encodeJpg(_image!);
      await imgprocSavedFile.writeAsBytes(bytes);
      //logger.d('IMPROC: Saved image $image to ${imgprocSavedFile.path}');
    
  }

  Future<void> dispose() async {
    _image = null;
    final directory = Directory(p.dirname(path));
    if (await directory.exists()) {
      final subDirectories =
          directory.listSync().whereType<Directory>().toList();
      List loggerList = [];
      int i = 0;
      for (var dir in subDirectories) {
        //await dir.delete(recursive: true);
        loggerList.add('${i++} $dir\n');
      }
      path = '';
      //logger.d('IMPROC: Image processor disposed');
    }
  }
}

class Ocr {
  final _textDetector = TextRecognizer();

  Future<String> extractText(final String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText =
          await _textDetector.processImage(inputImage);
      String text = '';
      for (TextBlock block in recognizedText.blocks) {
        text += '${block.text}\n';
        /* for (TextLine line in block.lines) {
          text += '${line.text}\n';
        } */
      }
      // return _postProcessText(text);
      //logger.d('OCR text: \n$text');
      return (text != '') ? text : 'No text found';
    } catch (e) {
      return '';
    }
  }

/*   String _postProcessText(String text) {
    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    // Trim leading/trailing spaces
    text = text.trim();
    return text;
  } */

  Future<void> dispose() async {
    await _textDetector.close();
    //logger.d('Text detector disposed');
  }
}
