import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/admin_url_builder.dart';
import '../../utils/env_config.dart';
import '../../utils/input_validator.dart';
import 'admin_api_gateway.dart';
import 'admin_payload_mapper.dart';
import 'admin_service.dart';
import 'mock_admin_service.dart';
import 'openapi_admin_service.dart';
import 'question_image_picker_service.dart';
import 'question_image_upload_service.dart';
import 's3_question_image_upload_service.dart';

/// 관리자 service 구현과 gateway/mapper 의존성을 구성하는 factory입니다.
/// Riverpod provider가 mock과 OpenAPI 구현을 교체할 때 이 클래스를 통해 wiring을 한 곳에 둡니다.
/// fields:
/// - [useMockService]: mock service 사용 여부를 결정하는 환경 설정입니다.
/// - [apiBaseUrl]: real gateway가 호출할 API base URL입니다.
/// - [voteCreatePath]: vote 생성 endpoint 경로를 환경별로 교체하는 값입니다.
/// - [gateway]: 테스트나 커스텀 실행에서 주입할 API gateway입니다.
/// - [mapper]: raw payload와 domain model을 변환하는 mapper입니다.
/// - [mockService]: 테스트에서 주입할 mock service 구현입니다.
class AdminServiceProvider {
  /// service factory 설정을 생성합니다.
  /// 기본값은 dart-define 기반 환경 설정과 real gateway 구성을 따릅니다.
  /// Parameters:
  /// - [useMockService]: mock service 사용 여부입니다.
  /// - [apiBaseUrl]: API base URL입니다.
  /// - [voteCreatePath]: vote 생성 endpoint 경로입니다.
  /// - [gateway]: 선택적으로 주입할 gateway 구현입니다.
  /// - [mapper]: payload mapper 구현입니다.
  /// - [mockService]: 선택적으로 주입할 mock service입니다.
  /// Returns:
  /// - [instance]: service 구현을 생성할 factory 인스턴스입니다.
  const AdminServiceProvider({
    this.useMockService = const bool.fromEnvironment('TAGLOW_USE_MOCK_SERVICE'),
    this.apiBaseUrl = const String.fromEnvironment(
      'TAGLOW_API_BASE_URL',
      defaultValue: DioAdminApiGateway.defaultBaseUrl,
    ),
    this.voteCreatePath = const String.fromEnvironment(
      'TAGLOW_VOTE_CREATE_PATH',
      defaultValue: DioAdminApiGateway.defaultVoteCreatePath,
    ),
    this.gateway,
    this.mapper = const AdminPayloadMapper(),
    this.mockService,
  });

  /// mock service를 사용할지 결정하는 플래그입니다.
  /// 테스트와 로컬 demo는 이 값으로 외부 API 의존성을 끊습니다.
  final bool useMockService;

  /// real gateway가 사용할 API base URL입니다.
  /// 비밀 값이 아닌 운영 설정이며 [DioAdminApiGateway]에 전달됩니다.
  final String apiBaseUrl;

  /// vote 생성 endpoint 경로 설정입니다.
  /// 서버의 로그인 사용자 보호 create endpoint 확정 전후 차이를 gateway 구성에서 흡수합니다.
  final String voteCreatePath;

  /// 외부에서 주입한 gateway 구현입니다.
  /// 테스트가 Dio 없이 service mapping을 검증할 때 사용할 수 있습니다.
  final AdminApiGateway? gateway;

  /// raw payload와 domain model 사이 변환을 담당하는 mapper입니다.
  /// OpenAPI service가 Gateway 결과를 Controller-facing model로 바꿀 때 사용합니다.
  final AdminPayloadMapper mapper;

  /// 외부에서 주입한 mock service 구현입니다.
  /// 테스트가 deterministic fixture를 제공할 때 사용할 수 있습니다.
  final AdminService? mockService;

  /// 현재 설정에 맞는 [AdminService] 구현을 생성합니다.
  /// mock mode에서는 [MockAdminService], real mode에서는 gateway와 mapper를 조합한 [OpenApiAdminService]를 반환합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: Controller가 사용할 관리자 service 구현입니다.
  AdminService create() {
    if (useMockService) {
      return mockService ?? MockAdminService();
    }

    return OpenApiAdminService(
      gateway:
          gateway ??
          DioAdminApiGateway(
            baseUrl: apiBaseUrl,
            voteCreatePath: voteCreatePath,
          ),
      mapper: mapper,
    );
  }
}

/// 환경 설정 값을 제공하는 Riverpod provider입니다.
/// Service와 utility wiring이 dart-define 값을 한 곳에서 읽게 합니다.
/// API, participant, player, S3 공개 설정처럼 비밀이 아닌 값만 노출합니다.
final envConfigProvider = Provider<EnvConfig>((ref) => const EnvConfig());

/// Controller가 사용하는 [AdminService] 구현을 제공하는 Riverpod provider입니다.
/// mock/real service 선택과 Gateway/Mapper 구성은 [AdminServiceProvider]가 담당합니다.
/// View와 Controller는 이 provider를 통해 service 계약만 의존합니다.
final adminServiceProvider = Provider<AdminService>((ref) {
  return const AdminServiceProvider().create();
});

/// 입력 validation helper를 제공하는 Riverpod provider입니다.
/// Controller와 service-adjacent validation이 같은 utility 정책을 재사용할 수 있습니다.
/// 현재 화면별 Controller validation과 동기화되어야 합니다.
final inputValidatorProvider = Provider<InputValidator>((ref) {
  return const InputValidator();
});

/// participant/player 운영 링크를 생성하는 URL builder provider입니다.
/// [EnvConfig]의 base URL을 주입해 Controller가 route 문자열을 직접 조립하지 않게 합니다.
/// QR payload는 builder가 만든 participant URL과 동일하게 유지됩니다.
final adminUrlBuilderProvider = Provider<AdminUrlBuilder>((ref) {
  final env = ref.watch(envConfigProvider);
  return AdminUrlBuilder(
    participantBaseUrl: env.participantBaseUrl,
    playerBaseUrl: env.playerBaseUrl,
  );
});

/// question 이미지 업로드 service를 제공하는 Riverpod provider입니다.
/// mock mode에서는 deterministic upload 결과를, real mode에서는 Cognito/S3 직접 업로드 구현을 반환합니다.
/// S3 설정이 누락되면 명확한 실패 service로 운영자에게 설정 문제를 알려줍니다.
final questionImageUploadServiceProvider = Provider<QuestionImageUploadService>(
  (ref) {
    const useMockService = bool.fromEnvironment('TAGLOW_USE_MOCK_SERVICE');
    if (useMockService) {
      return const MockQuestionImageUploadService();
    }
    final env = ref.watch(envConfigProvider);
    if (!env.hasS3UploadConfig) {
      return UnavailableQuestionImageUploadService(
        'S3 이미지 업로드 설정이 누락되었습니다: '
        '${env.missingS3UploadConfigKeys.join(', ')}',
      );
    }
    return S3QuestionImageUploadService(
      identityPoolId: env.cognitoIdentityPoolId,
      bucket: env.s3Bucket,
      region: env.s3Region,
      publicBaseUrl: env.s3PublicBaseUrl,
      questionImagePrefix: env.s3QuestionImagePrefix,
    );
  },
);

/// question 이미지 선택 service를 제공하는 Riverpod provider입니다.
/// mock mode에서는 파일 선택 창 없이 fixture를, real mode에서는 image_picker 구현을 사용합니다.
final questionImagePickerServiceProvider = Provider<QuestionImagePickerService>(
  (ref) {
    const useMockService = bool.fromEnvironment('TAGLOW_USE_MOCK_SERVICE');
    if (useMockService) {
      return const MockQuestionImagePickerService();
    }
    return ImagePickerQuestionImagePickerService();
  },
);
