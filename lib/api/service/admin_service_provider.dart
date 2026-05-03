import 'admin_api_gateway.dart';
import 'admin_payload_mapper.dart';
import 'admin_service.dart';
import 'mock_admin_service.dart';
import 'openapi_admin_service.dart';

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
