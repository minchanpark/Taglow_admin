import '../model/question_image_upload_result.dart';

/// question 이미지 업로드 실패를 사용자 표시용 메시지로 전달하는 예외입니다.
/// storage나 browser 내부 오류 문자열이 그대로 UI에 새지 않도록 service 경계에서 정규화합니다.
/// fields:
/// - [message]: 운영자에게 표시할 안전한 오류 메시지입니다.
class QuestionImageUploadException implements Exception {
  /// 이미지 업로드 예외를 생성합니다.
  /// Parameters:
  /// - [message]: 사용자 표시용 오류 메시지입니다.
  /// Returns:
  /// - [instance]: 이미지 업로드 실패 예외입니다.
  const QuestionImageUploadException(this.message);

  /// 운영자에게 표시할 안전한 오류 메시지입니다.
  final String message;

  /// 예외를 UI에 표시 가능한 문구로 변환합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 안전한 오류 메시지입니다.
  @override
  String toString() => message;
}

/// question 이미지 업로드 동작의 service 계약입니다.
/// Controller는 bytes, 파일명, MIME type, 크기만 넘기고 저장소 세부 구현은 이 경계 뒤에 둡니다.
/// 서버 question payload에는 이 service 결과의 publicUrl과 imageRatio만 전달됩니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
abstract class QuestionImageUploadService {
  /// question 이미지를 업로드하고 공개 URL과 이미지 비율을 반환합니다.
  /// 실제 구현은 S3 direct upload나 presigned URL PUT을 이 계약 뒤에 숨깁니다.
  /// Parameters:
  /// - [bytes]: 업로드할 이미지 byte 목록입니다.
  /// - [fileName]: 원본 또는 저장에 사용할 파일명입니다.
  /// - [contentType]: 이미지 MIME type입니다.
  /// - [imageWidth]: 원본 이미지 가로 픽셀입니다.
  /// - [imageHeight]: 원본 이미지 세로 픽셀입니다.
  /// Returns:
  /// - [result]: 업로드된 이미지의 공개 URL과 ratio 결과입니다.
  Future<QuestionImageUploadResult> uploadQuestionImage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required int imageWidth,
    required int imageHeight,
  });
}

/// real 이미지 업로드 구현이 연결되지 않았음을 명시하는 service입니다.
/// mock이 아닌 실행에서 upload action이 조용히 성공한 것처럼 보이지 않도록 실패를 반환합니다.
/// fields:
/// - [message]: 미연결 또는 설정 누락 상태를 설명하는 사용자 표시용 메시지입니다.
class UnavailableQuestionImageUploadService
    implements QuestionImageUploadService {
  /// 미연결 upload service 인스턴스를 생성합니다.
  /// provider가 real upload 구현 전까지 명시적 failure path를 제공할 때 사용합니다.
  /// Parameters:
  /// - [message]: 사용자 표시용 실패 메시지입니다.
  /// Returns:
  /// - [instance]: 업로드 미연결 상태를 나타내는 service 인스턴스입니다.
  const UnavailableQuestionImageUploadService([
    this.message = '이미지 업로드 서비스 설정이 필요합니다.',
  ]);

  /// 미연결 또는 설정 누락 상태를 설명하는 사용자 표시용 메시지입니다.
  final String message;

  /// 이미지 업로드 요청을 실패로 처리합니다.
  /// Controller는 이 오류를 사용자에게 upload service 연결 안내로 변환합니다.
  /// Parameters:
  /// - [bytes]: 업로드하려던 이미지 byte 목록입니다.
  /// - [fileName]: 업로드하려던 파일명입니다.
  /// - [contentType]: 이미지 MIME type입니다.
  /// - [imageWidth]: 원본 이미지 가로 픽셀입니다.
  /// - [imageHeight]: 원본 이미지 세로 픽셀입니다.
  /// Returns:
  /// - [result]: 이 구현은 정상 결과를 반환하지 않고 오류를 던집니다.
  @override
  Future<QuestionImageUploadResult> uploadQuestionImage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required int imageWidth,
    required int imageHeight,
  }) {
    throw QuestionImageUploadException(message);
  }
}

/// 외부 저장소 없이 deterministic한 이미지 업로드 결과를 반환하는 mock service입니다.
/// Controller와 View 테스트가 publicUrl, size, imageRatio 흐름을 실제 업로드 없이 검증하게 합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class MockQuestionImageUploadService implements QuestionImageUploadService {
  /// mock 이미지 업로드 service를 생성합니다.
  /// provider가 mock mode에서 이 구현을 주입합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: mock 업로드 service 인스턴스입니다.
  const MockQuestionImageUploadService();

  /// mock 이미지 업로드 결과를 생성합니다.
  /// 입력 크기로 imageRatio를 계산하고 파일명 기반 publicUrl fixture를 반환합니다.
  /// Parameters:
  /// - [bytes]: 업로드 fixture의 byte 목록입니다.
  /// - [fileName]: fixture URL에 사용할 파일명입니다.
  /// - [contentType]: 이미지 MIME type입니다.
  /// - [imageWidth]: 원본 이미지 가로 픽셀입니다.
  /// - [imageHeight]: 원본 이미지 세로 픽셀입니다.
  /// Returns:
  /// - [result]: mock publicUrl과 imageRatio를 담은 업로드 결과입니다.
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
