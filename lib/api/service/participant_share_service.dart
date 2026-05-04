import 'participant_share_service_base.dart';
import 'participant_share_service_platform_stub.dart'
    if (dart.library.js_interop) 'participant_share_service_platform_web.dart';

export 'participant_share_service_base.dart';

/// 현재 플랫폼에 맞는 [ParticipantShareService] 구현을 생성합니다.
/// Web에서는 Web Share API 구현을, 그 외 환경에서는 복사 fallback용 unsupported 구현을 반환합니다.
/// Parameters:
/// - [none]: 이 동작은 외부 입력 없이 현재 플랫폼 조건을 사용합니다.
/// Returns:
/// - [result]: Controller가 사용할 참여자 외부 공유 service입니다.
ParticipantShareService createParticipantShareService() {
  return createPlatformParticipantShareService();
}
