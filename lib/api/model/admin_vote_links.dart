/// vote 현장 운영에 필요한 링크 묶음을 표현하는 domain model입니다.
/// [AdminUrlBuilder]가 생성하고 Vote 상세 View가 participant, QR, player 흐름에 사용합니다.
/// fields:
/// - [voteId]: 링크들이 연결된 vote 식별자입니다.
/// - [participantUrl]: QR 스캔 후 이동할 공개 참여자 URL입니다.
/// - [participantQrPayload]: QR에 넣는 payload이며 MVP에서는 [participantUrl]과 같습니다.
/// - [playerUrl]: 스탠바이미 player display 화면으로 이동하는 URL입니다.
/// - [playerPreviewUrl]: post-MVP 진단이나 preview query가 필요할 때 쓰는 선택 URL입니다.
class AdminVoteLinks {
  /// 운영 링크 묶음을 생성합니다.
  /// URL builder가 voteId 기반 정책을 적용한 뒤 Controller/View에 전달합니다.
  /// Parameters:
  /// - [voteId]: 링크 생성 기준 vote 식별자입니다.
  /// - [participantUrl]: 모바일 참여자 화면 URL입니다.
  /// - [participantQrPayload]: QR 코드에 저장할 공개 payload입니다.
  /// - [playerUrl]: player display 화면 URL입니다.
  /// - [playerPreviewUrl]: 선택적인 player preview URL입니다.
  /// Returns:
  /// - [instance]: 운영 링크 값을 보관하는 새 인스턴스입니다.
  const AdminVoteLinks({
    required this.voteId,
    required this.participantUrl,
    required this.participantQrPayload,
    required this.playerUrl,
    this.playerPreviewUrl,
  });

  /// 링크 묶음이 속한 vote 식별자입니다.
  /// 파일명, QR export, player eventId 매핑의 기준으로 쓰입니다.
  final String voteId;

  /// 참여자가 QR이나 복사 링크로 들어갈 공개 URL입니다.
  /// 관리자 URL, token, 세션 정보가 포함되지 않아야 합니다.
  final String participantUrl;

  /// 참여자 QR 코드에 들어갈 payload입니다.
  /// 보안 정책상 공개 참여자 URL만 포함합니다.
  final String participantQrPayload;

  /// 스탠바이미 player display 화면으로 이동하는 공개 URL입니다.
  /// MVP에서는 voteId를 player eventId로 사용합니다.
  final String playerUrl;

  /// 진단용 player preview URL입니다.
  /// 현재 기본 흐름에서는 null이며 future extension 지점으로 유지됩니다.
  final String? playerPreviewUrl;
}
