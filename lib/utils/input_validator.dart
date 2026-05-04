/// 관리자 입력값의 반복 validation을 모아둔 utility입니다.
/// Controller validation과 Service boundary test가 같은 정책을 공유할 수 있게 합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class InputValidator {
  /// 상태 없는 validator를 생성합니다.
  /// provider를 통해 Controller나 service-adjacent 코드에 주입할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: 입력 validation utility 인스턴스입니다.
  const InputValidator();

  /// vote 이름이 비어 있는지 검증합니다.
  /// VoteListController의 생성 validation과 같은 정책을 유지해야 합니다.
  /// Parameters:
  /// - [value]: 검증할 vote 이름입니다.
  /// Returns:
  /// - [result]: 실패 메시지이거나 통과 시 null입니다.
  String? voteName(String value) {
    return value.trim().isEmpty ? 'Vote name is required.' : null;
  }

  /// question 이미지 URL이 비어 있는지 검증합니다.
  /// question 저장 payload에는 이미지 bytes가 아니라 URL이 필요합니다.
  /// Parameters:
  /// - [value]: 검증할 이미지 URL입니다.
  /// Returns:
  /// - [result]: 실패 메시지이거나 통과 시 null입니다.
  String? questionImageUrl(String value) {
    return value.trim().isEmpty ? 'Question image URL is required.' : null;
  }

  /// question imageRatio가 양수인지 검증합니다.
  /// 참여자와 player 레이아웃 계산에 사용할 수 없는 비율을 저장 전에 막습니다.
  /// Parameters:
  /// - [value]: 검증할 imageRatio 값입니다.
  /// Returns:
  /// - [result]: 실패 메시지이거나 통과 시 null입니다.
  String? positiveImageRatio(double value) {
    return value > 0 ? null : 'Question image ratio must be greater than zero.';
  }

  /// URL 환경 설정값이 비어 있는지 검증합니다.
  /// participant/player/S3 공개 URL 진단에서 label별 메시지를 만들 수 있습니다.
  /// Parameters:
  /// - [value]: 검증할 URL 설정값입니다.
  /// - [label]: 오류 메시지에 넣을 설정 이름입니다.
  /// Returns:
  /// - [result]: 실패 메시지이거나 통과 시 null입니다.
  String? nonEmptyUrlConfig(String value, String label) {
    return value.trim().isEmpty ? '$label is required.' : null;
  }
}
