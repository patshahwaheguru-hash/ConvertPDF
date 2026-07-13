if (_pdfBytes != null)
  Expanded(
    child: PdfPreview(
      build: (format) => _pdfBytes!,
      allowPrinting: true,
      allowSharing: true,
      initialPageFormat: PdfPageFormat.a4,
    ),
  ),
