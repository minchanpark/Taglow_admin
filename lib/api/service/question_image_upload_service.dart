import '../model/question_image_upload_result.dart';

abstract class QuestionImageUploadService {
  Future<QuestionImageUploadResult> uploadQuestionImage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required int imageWidth,
    required int imageHeight,
  });
}

class UnavailableQuestionImageUploadService
    implements QuestionImageUploadService {
  const UnavailableQuestionImageUploadService();

  @override
  Future<QuestionImageUploadResult> uploadQuestionImage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required int imageWidth,
    required int imageHeight,
  }) {
    throw StateError('Question image upload service is not connected.');
  }
}

class MockQuestionImageUploadService implements QuestionImageUploadService {
  const MockQuestionImageUploadService();

  @override
  Future<QuestionImageUploadResult> uploadQuestionImage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (imageWidth <= 0 || imageHeight <= 0) {
      throw ArgumentError('Image dimensions must be greater than zero.');
    }
    final safeFileName = fileName.trim().isEmpty
        ? 'mock-question.png'
        : fileName;
    return QuestionImageUploadResult(
      objectKey: 'public/question-images/$safeFileName',
      publicUrl:
          'https://cdn.taglow.local/public/question-images/$safeFileName',
      contentType: contentType,
      sizeBytes: bytes.length,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imageRatio: imageWidth / imageHeight,
    );
  }
}
