import '../api/model/admin_vote_links.dart';

/// participant, QR payload, player URL을 생성하는 utility입니다.
/// Controller가 voteId만 넘기면 PRD의 URL 정책을 적용한 [AdminVoteLinks]를 받을 수 있습니다.
/// endpoint나 route 문자열이 View에 흩어지지 않도록 이 helper가 담당합니다.
/// fields:
/// - [participantBaseUrl]: 참여자 모바일 화면의 base URL입니다.
/// - [playerBaseUrl]: 스탠바이미 player 화면의 base URL입니다.
class AdminUrlBuilder {
  /// URL builder를 생성합니다.
  /// provider가 [EnvConfig]의 participant/player base URL을 주입합니다.
  /// Parameters:
  /// - [participantBaseUrl]: participant URL 생성 기준 base URL입니다.
  /// - [playerBaseUrl]: player URL 생성 기준 base URL입니다.
  /// Returns:
  /// - [instance]: 운영 링크를 생성하는 builder 인스턴스입니다.
  const AdminUrlBuilder({
    required this.participantBaseUrl,
    required this.playerBaseUrl,
  });

  /// 참여자 모바일 화면의 base URL입니다.
  /// [buildParticipantUrl]이 `/e/{voteId}` 경로를 붙이는 기준입니다.
  final String participantBaseUrl;

  /// 스탠바이미 player 화면의 base URL입니다.
  /// [buildPlayerUrl]이 `/display/{voteId}` 경로를 붙이는 기준입니다.
  final String playerBaseUrl;

  /// voteId 기반 participant URL을 생성합니다.
  /// QR payload와 복사 링크는 이 공개 URL을 그대로 사용합니다.
  /// Parameters:
  /// - [voteId]: participant URL에 포함할 vote 식별자입니다.
  /// Returns:
  /// - [result]: `/e/{voteId}` 형식의 participant URL입니다.
  String buildParticipantUrl(String voteId) {
    return '${_trimRightSlash(participantBaseUrl)}/e/${_segment(voteId)}';
  }

  /// voteId 기반 player display URL을 생성합니다.
  /// MVP에서는 voteId가 player eventId로 매핑됩니다.
  /// Parameters:
  /// - [voteId]: player URL에 포함할 vote 식별자입니다.
  /// Returns:
  /// - [result]: `/display/{voteId}` 형식의 player URL입니다.
  String buildPlayerUrl(String voteId) {
    return '${_trimRightSlash(playerBaseUrl)}/display/${_segment(voteId)}';
  }

  /// 특정 question/item에 고정된 player URL을 생성합니다.
  /// player 문서의 itemId는 관리자 domain의 questionId와 매핑됩니다.
  /// Parameters:
  /// - [voteId]: player display 기준 vote 식별자입니다.
  /// - [questionId]: player item 경로에 포함할 question 식별자입니다.
  /// Returns:
  /// - [result]: `/display/{voteId}/items/{questionId}` 형식의 player URL입니다.
  String buildPlayerItemUrl({
    required String voteId,
    required String questionId,
  }) {
    return '${buildPlayerUrl(voteId)}/items/${_segment(questionId)}';
  }

  /// voteId에서 운영 링크 묶음을 생성합니다.
  /// QR payload는 보안 정책에 따라 participant URL과 동일한 공개 URL만 포함합니다.
  /// Parameters:
  /// - [voteId]: 링크 묶음을 생성할 vote 식별자입니다.
  /// Returns:
  /// - [result]: participant/player URL과 QR payload를 담은 [AdminVoteLinks]입니다.
  AdminVoteLinks buildVoteLinks(String voteId) {
    final participantUrl = buildParticipantUrl(voteId);
    return AdminVoteLinks(
      voteId: voteId,
      participantUrl: participantUrl,
      participantQrPayload: participantUrl,
      playerUrl: buildPlayerUrl(voteId),
    );
  }

  /// base URL 오른쪽 끝의 중복 slash를 제거합니다.
  /// 환경값에 trailing slash가 있어도 생성 URL이 안정적으로 유지됩니다.
  /// Parameters:
  /// - [value]: 정리할 base URL 문자열입니다.
  /// Returns:
  /// - [result]: 오른쪽 slash가 제거된 문자열입니다.
  String _trimRightSlash(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  /// path segment 값을 URL encode합니다.
  /// voteId와 questionId가 path 경계를 깨지 않도록 보호합니다.
  /// Parameters:
  /// - [value]: path segment로 사용할 문자열입니다.
  /// Returns:
  /// - [result]: URL encode된 segment 문자열입니다.
  String _segment(String value) => Uri.encodeComponent(value);
}
