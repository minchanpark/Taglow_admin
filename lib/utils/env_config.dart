class EnvConfig {
  const EnvConfig({
    this.apiBaseUrl = const String.fromEnvironment(
      'TAGLOW_API_BASE_URL',
      defaultValue: 'https://vote.newdawnsoi.site',
    ),
    this.participantBaseUrl = const String.fromEnvironment(
      'TAGLOW_PARTICIPANT_BASE_URL',
      defaultValue: 'https://taglow-acca6.web.app',
    ),
    this.playerBaseUrl = const String.fromEnvironment(
      'TAGLOW_PLAYER_BASE_URL',
      defaultValue: 'https://taglow-player.web.app',
    ),
    this.s3Bucket = const String.fromEnvironment('TAGLOW_S3_BUCKET'),
    this.s3Region = const String.fromEnvironment(
      'TAGLOW_AWS_REGION',
      defaultValue: 'ap-northeast-2',
    ),
    this.s3PublicBaseUrl = const String.fromEnvironment(
      'TAGLOW_S3_PUBLIC_BASE_URL',
    ),
  });

  final String apiBaseUrl;
  final String participantBaseUrl;
  final String playerBaseUrl;
  final String s3Bucket;
  final String s3Region;
  final String s3PublicBaseUrl;

  bool get hasParticipantBaseUrl => participantBaseUrl.trim().isNotEmpty;
  bool get hasPlayerBaseUrl => playerBaseUrl.trim().isNotEmpty;
  bool get hasS3PublicBaseUrl => s3PublicBaseUrl.trim().isNotEmpty;
}
