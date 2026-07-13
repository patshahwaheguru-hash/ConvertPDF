import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConvertPDF',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
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
  String? _savedPath;

  Future<void> _pickAndConvert() async {
    setState(() { _statusMessage = 'Picking file...'; });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null) { setState(() { _statusMessage = 'Cancelled'; }); return; }

      setState(() { _statusMessage = 'Creating PDF...'; });

      final pdf = pw.Document();
      pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, build: (pw.Context context) {
        return pw.Center(child: pw.Text('File: ${result.files.single.name}'));
      }));

      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/converted.pdf");
      await file.writeAsBytes(await pdf.save());

      setState(() { 
        _statusMessage = 'PDF Saved!';
        _savedPath = file.path;
      });

    } catch (e) {
      setState(() { _statusMessage = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: const Text('ConvertPDF')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Padding(padding: const EdgeInsets.all(16.0), child: Text(_statusMessage, style: TextStyle(fontSize: 16, color: _statusMessage.contains('Error')? Colors.red : Colors.black), textAlign: TextAlign.center)),
          ElevatedButton(onPressed: _pickAndConvert, child: const Text('Pick File & Create PDF')),
          const SizedBox(height: 10),
          if (_savedPath != null)
            Text('Saved to: $_savedPath', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
