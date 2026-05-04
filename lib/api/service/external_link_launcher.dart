/// 외부 링크를 브라우저 새 창으로 여는 동작의 service 계약입니다.
/// Controller는 player URL 열기 같은 브라우저 부수 효과를 이 경계 뒤로 위임합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
abstract class ExternalLinkLauncher {
  /// URL을 새 브라우저 탭이나 창으로 엽니다.
  /// player 화면 확인 흐름에서 실패 fallback은 Controller/View가 처리할 수 있습니다.
  /// Parameters:
  /// - [url]: 열 대상 공개 URL입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> openNewTab(String url);
}
