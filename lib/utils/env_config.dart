/// dart-define 기반 운영 설정을 모아 제공하는 config 값입니다.
/// 비밀 값이 아닌 API, participant, player, S3 공개 설정만 노출합니다.
/// Service provider와 URL builder가 이 값을 통해 환경 차이를 흡수합니다.
/// fields:
/// - [apiBaseUrl]: 관리자 API base URL입니다.
/// - [participantBaseUrl]: 참여자 링크 생성 기준 base URL입니다.
/// - [playerBaseUrl]: player 링크 생성 기준 base URL입니다.
/// - [s3Bucket]: 이미지 업로드 대상 bucket 이름 설정입니다.
/// - [s3Region]: 이미지 업로드 region 설정입니다.
/// - [s3PublicBaseUrl]: 업로드 이미지 공개 URL 생성 기준 설정입니다.
class EnvConfig {
  /// 환경 설정 값을 생성합니다.
  /// 기본값은 dart-define을 읽고, 테스트에서는 생성자 인자로 값을 덮어쓸 수 있습니다.
  /// Parameters:
  /// - [apiBaseUrl]: API base URL입니다.
  /// - [participantBaseUrl]: participant base URL입니다.
  /// - [playerBaseUrl]: player base URL입니다.
  /// - [s3Bucket]: S3 bucket 설정입니다.
  /// - [s3Region]: S3 region 설정입니다.
  /// - [s3PublicBaseUrl]: S3 public base URL 설정입니다.
  /// Returns:
  /// - [instance]: 환경 설정 값을 보관하는 config 인스턴스입니다.
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

  /// 관리자 API base URL입니다.
  /// [DioAdminApiGateway] 생성 시 사용할 수 있는 비밀이 아닌 운영 설정입니다.
  final String apiBaseUrl;

  /// participant URL 생성 기준 base URL입니다.
  /// [AdminUrlBuilder]가 `/e/{voteId}` 경로를 붙입니다.
  final String participantBaseUrl;

  /// player URL 생성 기준 base URL입니다.
  /// 기본값은 현재 StandbyMe player 배포 URL입니다.
  final String playerBaseUrl;

  /// question 이미지 업로드 대상 bucket 이름입니다.
  /// frontend 코드에는 장기 credential을 두지 않고 설정값만 보관합니다.
  final String s3Bucket;

  /// question 이미지 업로드 region 설정입니다.
  /// upload service가 실제 연결될 때 비밀이 아닌 region 정보로 사용할 수 있습니다.
  final String s3Region;

  /// 업로드된 이미지의 공개 URL을 만들 때 사용할 base URL입니다.
  /// 설정이 비어 있으면 upload service나 진단 화면에서 별도 안내할 수 있습니다.
  final String s3PublicBaseUrl;

  /// participant base URL 설정이 존재하는지 계산합니다.
  /// URL/QR 생성 가능 여부와 진단 화면의 누락 안내에 사용할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: participant base URL이 비어 있지 않은지 여부입니다.
  bool get hasParticipantBaseUrl => participantBaseUrl.trim().isNotEmpty;

  /// player base URL 설정이 존재하는지 계산합니다.
  /// player 링크 생성 가능 여부와 진단 화면의 누락 안내에 사용할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: player base URL이 비어 있지 않은지 여부입니다.
  bool get hasPlayerBaseUrl => playerBaseUrl.trim().isNotEmpty;

  /// S3 public base URL 설정이 존재하는지 계산합니다.
  /// image upload 결과 URL을 만들 수 있는지 확인하는 데 사용됩니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: S3 public base URL이 비어 있지 않은지 여부입니다.
  bool get hasS3PublicBaseUrl => s3PublicBaseUrl.trim().isNotEmpty;
}
