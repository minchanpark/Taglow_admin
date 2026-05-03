class QuestionImageUploadResult {
  const QuestionImageUploadResult({
    required this.objectKey,
    required this.publicUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageRatio,
  });

  final String objectKey;
  final String publicUrl;
  final String contentType;
  final int sizeBytes;
  final int imageWidth;
  final int imageHeight;
  final double imageRatio;
}
