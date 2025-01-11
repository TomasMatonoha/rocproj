import 'package:epubx/epubx.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:logger/logger.dart';


class TextToEpubConverter {
  final _logger = Logger();
  
  Future<void> createEpub()async{

  }

  Future<void> convertToEpub({
    // nejspis musim ulozit pages do xml souboru a ten nahrat do epubcontentfile?
    required final List<String> pages,
    required final String outputPath,
    required final String language,
  }) async {
    var book = EpubBook();
    _logger.d('Book initialized');
    book.Title = 'Generated EPUB';
    book.Chapters = [];
    for (final page in pages) {
      var chapter = EpubChapter();
      chapter.HtmlContent = '<html><body>$page</body></html>';      
      _logger.d(chapter.HtmlContent);
      
      book.Chapters!.add(chapter);
    }
    _logger.d('bytes');
    final bytes = EpubWriter.writeBook(book);
    _logger.d('file');
    var file = File(outputPath);
    _logger.d('write');
    await file.writeAsBytes(bytes!);
  }
}

class TextToPdfConverter {

  Future<void> convertToPdf({
    required final List<String> pages,
    required final String outputPath,
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

    final file = File('$outputPath/${DateTime.now().millisecondsSinceEpoch}-${pages.length}.pdf');
    await file.writeAsBytes(await pdf.save());
  }
}