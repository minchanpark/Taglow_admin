class AdminVoteLinks {
  const AdminVoteLinks({
    required this.voteId,
    required this.participantUrl,
    required this.participantQrPayload,
    required this.playerUrl,
    this.playerPreviewUrl,
  });

  final String voteId;
  final String participantUrl;
  final String participantQrPayload;
  final String playerUrl;
  final String? playerPreviewUrl;
}
