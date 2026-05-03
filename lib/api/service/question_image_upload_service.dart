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
