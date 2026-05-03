import '../api/model/admin_vote_links.dart';

class AdminUrlBuilder {
  const AdminUrlBuilder({
    required this.participantBaseUrl,
    required this.playerBaseUrl,
  });

  final String participantBaseUrl;
  final String playerBaseUrl;

  String buildParticipantUrl(String voteId) {
    return '${_trimRightSlash(participantBaseUrl)}/e/${_segment(voteId)}';
  }

  String buildPlayerUrl(String voteId) {
    return '${_trimRightSlash(playerBaseUrl)}/display/${_segment(voteId)}';
  }

  String buildPlayerItemUrl({
    required String voteId,
    required String questionId,
  }) {
    return '${buildPlayerUrl(voteId)}/items/${_segment(questionId)}';
  }

  AdminVoteLinks buildVoteLinks(String voteId) {
    final participantUrl = buildParticipantUrl(voteId);
    return AdminVoteLinks(
      voteId: voteId,
      participantUrl: participantUrl,
      participantQrPayload: participantUrl,
      playerUrl: buildPlayerUrl(voteId),
    );
  }

  String _trimRightSlash(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  String _segment(String value) => Uri.encodeComponent(value);
}
