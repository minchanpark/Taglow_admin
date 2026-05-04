/// question 이미지 업로드 전에 선택된 로컬 이미지 값입니다.
/// Controller는 이 값을 즉시 업로드 service로 넘기고 장기 상태로 보관하지 않습니다.
/// fields:
/// - [bytes]: 선택된 이미지 byte 목록입니다.
/// - [fileName]: 원본 파일명입니다.
/// - [contentType]: 이미지 MIME type입니다.
/// - [imageWidth]: 원본 이미지 가로 픽셀입니다.
/// - [imageHeight]: 원본 이미지 세로 픽셀입니다.
class QuestionImageSelection {
  /// 선택된 이미지 정보를 생성합니다.
  /// Parameters:
  /// - [bytes]: 선택된 이미지 bytes입니다.
  /// - [fileName]: 파일명입니다.
  /// - [contentType]: MIME type입니다.
  /// - [imageWidth]: 이미지 가로 픽셀입니다.
  /// - [imageHeight]: 이미지 세로 픽셀입니다.
  /// Returns:
  /// - [instance]: 업로드 전 이미지 선택 값입니다.
  const QuestionImageSelection({
    required this.bytes,
    required this.fileName,
    required this.contentType,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// 선택된 이미지 byte 목록입니다.
  /// 업로드 service로 전달된 뒤 Controller state에는 저장하지 않습니다.
  final List<int> bytes;

  /// 원본 파일명입니다.
  /// 저장소 object key 확장자와 운영 진단에 사용할 수 있습니다.
  final String fileName;

  /// 선택 이미지 MIME type입니다.
  /// S3 PUT의 Content-Type과 저장 결과 값에 사용됩니다.
  final String contentType;

  /// 이미지 원본 가로 픽셀입니다.
  /// imageRatio 계산 입력입니다.
  final int imageWidth;

  /// 이미지 원본 세로 픽셀입니다.
  /// imageRatio 계산 입력입니다.
  final int imageHeight;
}
