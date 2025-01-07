import 'package:logger/logger.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';


class TextToPdfConverter {
  Logger logger = Logger();

  Future<void> convertToPdf({
    required List<String> pages,
    required String outputPath,
    double fontSize = 12,
  }) async {
    var pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    for (String pageText in pages) {
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Center(
              child: pw.Column(
                children:[
                  pw.Text(
                    pageText,style: pw.TextStyle(
                    fontSize: fontSize,
                    font: font),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final file = File(outputPath);
    await file.writeAsBytes(await pdf.save());
    logger.d('PDF saved to $outputPath');
  }
}