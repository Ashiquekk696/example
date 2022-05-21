import 'package:flutter/material.dart';
import 'package:flutter_filereader/flutter_filereader.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfReaderPage extends StatefulWidget {
  var filePath;
  var fileName;
  PdfReaderPage({Key: Key, this.filePath, this.fileName});

  @override
  _PdfReaderPageState createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          widget.fileName ?? "",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SfPdfViewer.memory(
        widget.filePath,
        pageSpacing: 4,
      ),
    );
  }
}
