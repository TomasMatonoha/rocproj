import 'dart:io';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;


class TextToPdfConverter {
  final List<String> _bookContent;
  final String _outputPath;

  TextToPdfConverter({
    required List<String> bookContent,
    required String outputPath,
  })  : _outputPath = outputPath,
        _bookContent = bookContent;

  Future<void> convertToPdf({final double fontSize = 12}) async {
    var pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    for (String pageText in _bookContent) {
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    pageText,
                    style: pw.TextStyle(fontSize: fontSize, font: font),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final file = File(
        '$_outputPath/pdfebook-${DateTime.now().millisecondsSinceEpoch}-${_bookContent.length}.pdf');
    await file.writeAsBytes(await pdf.save());
  }
}
