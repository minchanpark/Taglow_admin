/// 참여자 링크를 운영체제나 브라우저의 공유 UI로 넘기는 service 계약입니다.
/// Web Share API 같은 플랫폼 세부사항을 Controller와 View 밖으로 분리합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 구현체가 플랫폼 공유 가능 여부를 판단합니다.
abstract class ParticipantShareService {
  /// 참여자 링크를 외부 공유 UI로 전달합니다.
  /// 공유가 지원되지 않거나 차단되면 [ParticipantShareException]을 던질 수 있습니다.
  /// Parameters:
  /// - [title]: 공유 sheet에 전달할 제목입니다.
  /// - [text]: 링크와 함께 전달할 짧은 본문입니다.
  /// - [url]: 공유할 공개 참여자 URL입니다.
  /// Returns:
  /// - [completion]: 외부 공유 요청 완료를 의미합니다.
  Future<void> shareParticipantLink({
    required String title,
    required String text,
    required String url,
  });
}

/// 참여자 링크 외부 공유 실패를 표현하는 예외입니다.
/// Controller는 [shouldFallbackToCopy]를 보고 링크 복사 fallback 여부를 결정합니다.
/// fields:
/// - [message]: 운영자에게 표시할 수 있는 실패 메시지입니다.
/// - [shouldFallbackToCopy]: 공유 실패 시 참여자 링크 복사를 시도할지 여부입니다.
class ParticipantShareException implements Exception {
  /// 외부 공유 실패 예외를 생성합니다.
  /// Parameters:
  /// - [message]: 실패 메시지입니다.
  /// - [shouldFallbackToCopy]: 링크 복사 fallback 수행 여부입니다.
  /// Returns:
  /// - [instance]: 외부 공유 실패 정보를 담은 예외입니다.
  const ParticipantShareException(
    this.message, {
    this.shouldFallbackToCopy = true,
  });

  /// 사용자에게 표시할 수 있는 실패 메시지입니다.
  final String message;

  /// 공유가 불가할 때 참여자 링크 복사 fallback을 수행할지 여부입니다.
  final bool shouldFallbackToCopy;

  /// 예외를 로그나 테스트에서 읽기 쉬운 문자열로 변환합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 실패 메시지 문자열입니다.
  @override
  String toString() => message;
}
