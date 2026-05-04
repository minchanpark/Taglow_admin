/// 이미지 크기에서 question imageRatio를 계산하는 utility입니다.
/// Upload service나 Controller-adjacent validation이 같은 비율 정책을 재사용하게 합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class ImageRatioReader {
  /// 상태 없는 이미지 비율 계산기를 생성합니다.
  /// 테스트와 upload service wiring에서 직접 사용할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: 이미지 비율 계산 utility 인스턴스입니다.
  const ImageRatioReader();

  /// 이미지 가로/세로 픽셀에서 가로/세로 비율을 계산합니다.
  /// 0 이하 크기는 저장 payload에 잘못된 imageRatio가 들어가지 않도록 오류로 처리합니다.
  /// Parameters:
  /// - [width]: 이미지 원본 가로 픽셀입니다.
  /// - [height]: 이미지 원본 세로 픽셀입니다.
  /// Returns:
  /// - [result]: width / height로 계산한 imageRatio입니다.
  double fromDimensions({required int width, required int height}) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Image width and height must be greater than zero.');
    }
    return width / height;
  }
}
