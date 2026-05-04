/// dart-define 기반 운영 설정을 모아 제공하는 config 값입니다.
/// 비밀 값이 아닌 API, participant, player, S3 공개 설정만 노출합니다.
/// Service provider와 URL builder가 이 값을 통해 환경 차이를 흡수합니다.
/// fields:
/// - [apiBaseUrl]: 관리자 API base URL입니다.
/// - [participantBaseUrl]: 참여자 링크 생성 기준 base URL입니다.
/// - [playerBaseUrl]: player 링크 생성 기준 base URL입니다.
/// - [cognitoIdentityPoolId]: S3 업로드용 Cognito Identity Pool 식별자입니다.
/// - [s3Bucket]: 이미지 업로드 대상 bucket 이름 설정입니다.
/// - [s3Region]: 이미지 업로드 region 설정입니다.
/// - [s3PublicBaseUrl]: 업로드 이미지 공개 URL 생성 기준 설정입니다.
/// - [s3QuestionImagePrefix]: question 이미지 S3 object key prefix입니다.
class EnvConfig {
  /// 환경 설정 값을 생성합니다.
  /// 기본값은 dart-define을 읽고, 테스트에서는 생성자 인자로 값을 덮어쓸 수 있습니다.
  /// Parameters:
  /// - [apiBaseUrl]: API base URL입니다.
  /// - [participantBaseUrl]: participant base URL입니다.
  /// - [playerBaseUrl]: player base URL입니다.
  /// - [cognitoIdentityPoolId]: Cognito Identity Pool 식별자입니다.
  /// - [s3Bucket]: S3 bucket 설정입니다.
  /// - [s3Region]: S3 region 설정입니다.
  /// - [s3PublicBaseUrl]: S3 public base URL 설정입니다.
  /// - [s3QuestionImagePrefix]: question 이미지 저장 prefix입니다.
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
    this.cognitoIdentityPoolId = const String.fromEnvironment(
      'TAGLOW_COGNITO_IDENTITY_POOL_ID',
      defaultValue: 'ap-northeast-2:9015b01d-8637-43f6-a4cb-2e77be70a6f2',
    ),
    this.s3Bucket = const String.fromEnvironment(
      'TAGLOW_S3_BUCKET',
      defaultValue: 'tagvote-content-bucket',
    ),
    this.s3Region = const String.fromEnvironment(
      'TAGLOW_AWS_REGION',
      defaultValue: 'ap-northeast-2',
    ),
    this.s3PublicBaseUrl = const String.fromEnvironment(
      'TAGLOW_S3_PUBLIC_BASE_URL',
      defaultValue:
          'https://tagvote-content-bucket.s3.ap-northeast-2.amazonaws.com',
    ),
    this.s3QuestionImagePrefix = const String.fromEnvironment(
      'TAGLOW_S3_QUESTION_IMAGE_PREFIX',
      defaultValue: 'public/question-images',
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

  /// S3 직접 업로드용 Cognito Identity Pool 식별자입니다.
  /// 장기 AWS credential이 아니며 Identity Pool에서 임시 자격 증명을 받을 때 사용합니다.
  final String cognitoIdentityPoolId;

  /// question 이미지 업로드 대상 bucket 이름입니다.
  /// frontend 코드에는 장기 credential을 두지 않고 설정값만 보관합니다.
  final String s3Bucket;

  /// question 이미지 업로드 region 설정입니다.
  /// upload service가 실제 연결될 때 비밀이 아닌 region 정보로 사용할 수 있습니다.
  final String s3Region;

  /// 업로드된 이미지의 공개 URL을 만들 때 사용할 base URL입니다.
  /// 설정이 비어 있으면 upload service나 진단 화면에서 별도 안내할 수 있습니다.
  final String s3PublicBaseUrl;

  /// question 이미지 object key prefix입니다.
  /// 기본값은 public read 정책과 IAM prefix 정책이 기대하는 `public/question-images`입니다.
  final String s3QuestionImagePrefix;

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

  /// Cognito 기반 S3 직접 업로드에 필요한 설정이 모두 있는지 계산합니다.
  /// 업로드 provider가 real service와 설정 누락 안내 service를 선택할 때 사용합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: S3 upload service를 구성할 수 있는지 여부입니다.
  bool get hasS3UploadConfig {
    return missingS3UploadConfigKeys.isEmpty;
  }

  /// Cognito/S3 직접 업로드 설정 중 누락된 dart-define key 목록입니다.
  /// 운영자 오류 메시지와 진단 화면에서 어떤 값이 비었는지 설명할 때 사용합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 비어 있는 S3 upload 설정 key 목록입니다.
  List<String> get missingS3UploadConfigKeys {
    final keys = <String>[];
    if (cognitoIdentityPoolId.trim().isEmpty) {
      keys.add('TAGLOW_COGNITO_IDENTITY_POOL_ID');
    }
    if (s3Bucket.trim().isEmpty) {
      keys.add('TAGLOW_S3_BUCKET');
    }
    if (s3Region.trim().isEmpty) {
      keys.add('TAGLOW_AWS_REGION');
    }
    if (s3PublicBaseUrl.trim().isEmpty) {
      keys.add('TAGLOW_S3_PUBLIC_BASE_URL');
    }
    if (s3QuestionImagePrefix.trim().isEmpty) {
      keys.add('TAGLOW_S3_QUESTION_IMAGE_PREFIX');
    }
    return keys;
  }
}
