/// 클립보드 복사 동작을 감싸는 utility 계약입니다.
/// participant/player 링크 복사 같은 browser 부수 효과를 View/Controller 밖으로 분리합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
abstract class ClipboardHelper {
  /// 문자열을 시스템 클립보드에 복사합니다.
  /// 링크 복사 실패 시 Controller나 View가 fallback 안내를 제공할 수 있습니다.
  /// Parameters:
  /// - [value]: 복사할 문자열입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> copyText(String value);
}
