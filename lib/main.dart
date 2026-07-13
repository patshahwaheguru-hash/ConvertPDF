import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConvertPDF',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _statusMessage = 'Ready';
  Uint8List? _pdfBytes;

  Future<void> _pickAndConvert() async {
    setState(() { _statusMessage = 'Picking file...'; });
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null) {
        setState(() { _statusMessage = 'Cancelled'; });
        return;
      }

      setState(() { _statusMessage = 'Creating PDF...'; });

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('File: ${result.files.single.name}'),
            );
          },
        ),
      );

      _pdfBytes = await pdf.save();
      setState(() { _statusMessage = 'PDF Created Successfully'; });

    } catch (e) {
      setState(() { _statusMessage = 'Error: $e'; });
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) {
      setState(() { _statusMessage = 'Error: Create PDF first'; });
      return;
    }
    setState(() { _statusMessage = 'Opening Print...'; });
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => _pdfBytes!,
    );
    setState(() { _statusMessage = 'Print Dialog Opened'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ConvertPDF'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: _statusMessage.contains('Error') ? Colors.red : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: _pickAndConvert,
              child: const Text('Pick File & Create PDF'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pdfBytes != null ? _printPdf : null,
              child: const Text('Print PDF'),
            ),
            const SizedBox(height: 20),
            // NO size: parameter here
            if (_pdfBytes != null)
              Expanded(
                child: PdfPreview(
                  build: (format) => _pdfBytes!,
                  allowPrinting: true,
                  allowSharing: true,
                  initialPageFormat: PdfPageFormat.a4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
