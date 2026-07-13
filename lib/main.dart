import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConvertPDF',
      theme: ThemeData(useMaterial3: true),
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
  String _status = 'Ready';
  String? _path;

  Future<void> _createPdf() async {
    setState(() => _status = 'Picking file...');
    final result = await FilePicker.platform.pickFiles();
    if (result == null) { setState(() => _status = 'Cancelled'); return; }

    setState(() => _status = 'Creating PDF...');
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Text(result.files.single.name))));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/converted.pdf');
    await file.writeAsBytes(await pdf.save());

    setState(() {
      _status = 'PDF Saved!';
      _path = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ConvertPDF')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_status, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _createPdf, child: const Text('Pick File & Create PDF')),
        if (_path != null) Padding(padding: const EdgeInsets.all(8), child: Text('Saved: $_path', style: const TextStyle(fontSize: 12)))
      ])),
    );
  }
}
