import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:logger/logger.dart';

class ImageProcessor {
  static const int maxDimension = 1080;
  static const int minDimension = 100;
  img.Image? image;
  late String path;
  Logger logger = Logger();

  Future<void> loadImage(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    image = img.decodeImage(bytes);
    path = imagePath;
    logger.i(image);
    
  }

  bool enforceSizeLimits() {
    int width = image!.width;
    int height = image!.height;

    // image too large - resize for less memory usage
    if (width > maxDimension || height > maxDimension) {
      double scale = maxDimension / math.max(width, height);
      width = (width * scale).round();
      height = (height * scale).round();
      image = img.copyResize(image!, width: width, height: height);
      logger.i('Resized image to $width x $height');
      return true;
    }
    // image too small - reject
    if (width < minDimension || height < minDimension) {
      logger.i('Image too small');
      return false;
    }
    return true;
  }

  void convertToGrayscale() {
    image = img.grayscale(image!);
  }

  void reduceNoise() {
    image = img.gaussianBlur(image!, radius: 1);
  }

  void applyThreshold(int threshold) {
    image = img.luminanceThreshold(image!, threshold: threshold);
  }

  void adjustBrightness(double factor) {
    image = img.adjustColor(
      image!,
      brightness: factor,
    );
  }

  void adjustContrast(double factor) {
    image = img.adjustColor(
      image!,
      contrast: factor,
    );
  }

  void optimizeForOCR() {
    if (!enforceSizeLimits()) {
      throw Exception('Image too small');
    }
    adjustBrightness(0.5);
    adjustContrast(0.5);
    reduceNoise();
    convertToGrayscale();
    reduceNoise();
    logger.i('Optimized image for OCR');
  }

  Future<void> save() async {
    final bytes = img.encodeJpg(image!);
    await File(path).writeAsBytes(bytes);
    logger.i('Saved image to $path');
  }
}

class Ocr {
  final textDetector = TextRecognizer();
  final Logger logger = Logger();

  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textDetector.processImage(inputImage);
      String text = '';
      for (TextBlock block in recognizedText.blocks) {
        text += '${block.text}\n';
        /* for (TextLine line in block.lines) {
          text += '${line.text}\n';
        } */
      }
      // return _postProcessText(text);
      logger.i('OCR text: $text');
      return text;
    } catch (e) {
      logger.e('OCR error: $e');
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
    await textDetector.close();
    logger.i('Text detector closed');
  }
}
