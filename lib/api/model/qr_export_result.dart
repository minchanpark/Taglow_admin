enum QrExportFormat { png, svg }

class QrExportResult {
  const QrExportResult({
    required this.fileName,
    required this.format,
    required this.byteLength,
  });

  final String fileName;
  final QrExportFormat format;
  final int byteLength;
}
