import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/admin_url_builder.dart';
import '../../utils/env_config.dart';
import '../../utils/input_validator.dart';
import 'admin_api_gateway.dart';
import 'admin_payload_mapper.dart';
import 'admin_service.dart';
import 'mock_admin_service.dart';
import 'openapi_admin_service.dart';
import 'question_image_upload_service.dart';

class AdminServiceProvider {
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

  final bool useMockService;
  final String apiBaseUrl;
  final String voteCreatePath;
  final AdminApiGateway? gateway;
  final AdminPayloadMapper mapper;
  final AdminService? mockService;

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

final envConfigProvider = Provider<EnvConfig>((ref) => const EnvConfig());

final adminServiceProvider = Provider<AdminService>((ref) {
  return const AdminServiceProvider().create();
});

final inputValidatorProvider = Provider<InputValidator>((ref) {
  return const InputValidator();
});

final adminUrlBuilderProvider = Provider<AdminUrlBuilder>((ref) {
  final env = ref.watch(envConfigProvider);
  return AdminUrlBuilder(
    participantBaseUrl: env.participantBaseUrl,
    playerBaseUrl: env.playerBaseUrl,
  );
});

final questionImageUploadServiceProvider =
    Provider<QuestionImageUploadService>((ref) {
      const useMockService = bool.fromEnvironment('TAGLOW_USE_MOCK_SERVICE');
      if (useMockService) {
        return const MockQuestionImageUploadService();
      }
      return const UnavailableQuestionImageUploadService();
    });
