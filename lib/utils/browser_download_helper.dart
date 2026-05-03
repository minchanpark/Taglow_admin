abstract class BrowserDownloadHelper {
  Future<void> downloadBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  });

  Future<void> downloadText({
    required String text,
    required String fileName,
    required String mimeType,
  });
}
