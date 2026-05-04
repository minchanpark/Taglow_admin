/// question 이미지 업로드가 끝난 뒤 앱에서 보관하는 결과 model입니다.
/// Controller는 이 값에서 [publicUrl]과 [imageRatio]만 question 저장 payload로 넘깁니다.
/// fields:
/// - [objectKey]: 업로드 저장소에서 식별하는 객체 경로입니다.
/// - [publicUrl]: 참여자와 player 화면이 읽을 수 있는 공개 이미지 URL입니다.
/// - [contentType]: 업로드된 이미지 MIME type입니다.
/// - [sizeBytes]: 업로드된 파일 크기입니다.
/// - [imageWidth]: 원본 이미지 가로 픽셀입니다.
/// - [imageHeight]: 원본 이미지 세로 픽셀입니다.
/// - [imageRatio]: 원본 가로/세로 비율이며 서버 payload에 전달됩니다.
class QuestionImageUploadResult {
  /// 이미지 업로드 결과를 생성합니다.
  /// Upload service가 저장소 세부 구현을 숨기고 Controller에 안정적인 값을 반환합니다.
  /// Parameters:
  /// - [objectKey]: 저장소 객체 식별자입니다.
  /// - [publicUrl]: 공개 이미지 URL입니다.
  /// - [contentType]: 이미지 MIME type입니다.
  /// - [sizeBytes]: 업로드 파일 크기입니다.
  /// - [imageWidth]: 이미지 가로 크기입니다.
  /// - [imageHeight]: 이미지 세로 크기입니다.
  /// - [imageRatio]: 이미지 가로/세로 비율입니다.
  /// Returns:
  /// - [instance]: 업로드 결과 값을 보관하는 새 인스턴스입니다.
  const QuestionImageUploadResult({
    required this.objectKey,
    required this.publicUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageRatio,
  });

  /// 저장소 내부에서 사용하는 업로드 객체 키입니다.
  /// UI에는 노출하지 않고 service와 진단 흐름의 기술 값으로 유지됩니다.
  final String objectKey;

  /// question 저장 payload에 전달할 공개 이미지 URL입니다.
  /// 서버에는 이미지 bytes가 아니라 이 값이 저장됩니다.
  final String publicUrl;

  /// 업로드된 이미지의 MIME type입니다.
  /// upload service와 mock service가 파일 처리 결과를 설명합니다.
  final String contentType;

  /// 업로드된 이미지의 byte 크기입니다.
  /// 진단과 테스트에서 업로드 결과 검증에 사용할 수 있습니다.
  final int sizeBytes;

  /// 업로드 이미지의 원본 가로 픽셀입니다.
  /// [imageRatio] 계산의 입력으로 보관됩니다.
  final int imageWidth;

  /// 업로드 이미지의 원본 세로 픽셀입니다.
  /// [imageRatio] 계산의 입력으로 보관됩니다.
  final int imageHeight;

  /// 업로드 이미지의 원본 가로/세로 비율입니다.
  /// question 저장 시 서버로 전달되어 참여자와 player 레이아웃에 사용됩니다.
  final double imageRatio;
}
