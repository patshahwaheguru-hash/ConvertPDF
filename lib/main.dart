import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
   );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
@override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<File> _selectedFiles = [];
  bool _isConverting = false;
  String _statusMessage = '';

  Future<void> _pickFiles(String type) async {
    FilePickerResult? result;

    if (type == 'jpg') {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
    } else if (type == 'excel') {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );
    }

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles = result.files.map((f) => File(f.path!)).toList();
        _statusMessage = '';
      });
    }
  }
}
  
Future<void> _convertToPdf() async {
    if (_selectedFiles.isEmpty) {
      setState(() {
        _statusMessage = 'Please select a file first';
      });
      return;
    }

    setState(() {
      _isConverting = true;
      _statusMessage = 'Converting...';
    });

    try {
      final pdf = pw.Document();
      final file = _selectedFiles.first;
      final extension = file.path.split('.').last.toLowerCase();

      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
        await _convertImageToPdf(pdf, file);
      } else if (extension == 'xlsx' || extension == 'xls') {
        await _convertExcelToPdf(pdf, file);
      }

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(await pdf.save());

       setState(() {
        _isConverting = false;
        _statusMessage = 'Conversion successful!';
      });

      // Share the PDF
      await Share.shareXFiles([XFile(outputPath)], text: 'Converted PDF');

    } catch (e) {
      setState(() {
        _isConverting = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _convertImageToPdf(pw.Document pdf, File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ),
    );
  }

    Future<void> _convertExcelToPdf(pw.Document pdf, File excelFile) async {
    final bytes = await excelFile.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null) continue;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Text(table)),
              pw.TableHelper.fromTextArray(
                context: context,
                data: sheet.rows.map((row) {
                  return row.map((cell) {
                    return cell?.value?.toString() ?? '';
                  }).toList();
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerAlignment: pw.Alignment.centerLeft,
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(4),
              ),
            ];
          },
        ),
      );
    }
  }

   @override 
   Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Converter'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // JPG Button
            ElevatedButton.icon(
              onPressed: () => _pickFiles('jpg'),
              icon: const Icon(Icons.image),
              label: const Text('Select JPG/PNG Images'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
      const SizedBox(height: 12),

            // Excel Button
            ElevatedButton.icon(
              onPressed: () => _pickFiles('excel'),
              icon: const Icon(Icons.table_chart),
              label: const Text('Select Excel File (.xlsx/.xls)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Selected Files
            if (_selectedFiles.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Files:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
const SizedBox(height: 8),
                      ..._selectedFiles.map((file) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          file.path.split('/').last,
                          style: const TextStyle(fontSize: 14),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Convert Button
            ElevatedButton.icon(
              onPressed: _isConverting ? null : _convertToPdf,
              icon: _isConverting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isConverting ? 'Converting...' : 'Convert to PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),
            
            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('Error')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                color: _statusMessage.contains('Error')
                  ? Colors.red.shade900
                   : Colors.green.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
