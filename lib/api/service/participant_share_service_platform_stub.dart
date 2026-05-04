import 'participant_share_service_base.dart';

/// 현재 플랫폼에서 사용할 참여자 공유 service를 생성합니다.
/// Web Share API를 사용할 수 없는 플랫폼에서는 unsupported 구현을 반환합니다.
/// Parameters:
/// - [none]: 이 동작은 외부 입력 없이 현재 플랫폼 조건을 사용합니다.
/// Returns:
/// - [result]: 플랫폼 공유 service 구현입니다.
ParticipantShareService createPlatformParticipantShareService() {
  return const UnsupportedParticipantShareService();
}

/// Web Share API가 없는 환경에서 사용하는 공유 service 구현입니다.
/// Controller가 이 실패를 받아 참여자 링크 복사 fallback을 제공할 수 있습니다.
/// fields:
/// - [none]: 저장 필드가 없으며 모든 공유 요청을 unsupported로 처리합니다.
class UnsupportedParticipantShareService implements ParticipantShareService {
  /// unsupported 공유 service를 생성합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: 외부 공유 미지원 service 인스턴스입니다.
  const UnsupportedParticipantShareService();

  /// 외부 공유를 지원하지 않는다는 예외를 던집니다.
  /// Parameters:
  /// - [title]: 공유 제목이며 unsupported 구현에서는 사용하지 않습니다.
  /// - [text]: 공유 본문이며 unsupported 구현에서는 사용하지 않습니다.
  /// - [url]: 공유 URL이며 fallback 복사 대상입니다.
  /// Returns:
  /// - [completion]: 항상 예외로 완료됩니다.
  @override
  Future<void> shareParticipantLink({
    required String title,
    required String text,
    required String url,
  }) async {
    throw const ParticipantShareException('외부 공유를 지원하지 않는 환경입니다.');
  }
}
