import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'admin_dio_adapter_stub.dart'
    if (dart.library.html) 'admin_dio_adapter_web.dart';

/// 관리자 API의 low-level 호출을 담당하는 Gateway 계약입니다.
/// endpoint path, header, credential, Dio/generated-client 변화는 이 경계 뒤에 머물러야 합니다.
/// Service는 이 Gateway에서 받은 raw payload를 Mapper로 넘겨 domain model로 바꿉니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
abstract class AdminApiGateway {
  /// 회원가입 API를 호출하고 생성된 사용자 payload를 반환합니다.
  /// Auth Service가 payload 생성과 domain model 변환을 앞뒤에서 담당합니다.
  /// Parameters:
  /// - [payload]: Mapper가 만든 signup 요청 payload입니다.
  /// Returns:
  /// - [result]: Gateway가 정규화한 사용자 payload입니다.
  Future<Map<String, Object?>> signup(Map<String, Object?> payload);

  /// 로그인 API를 호출하고 인증 사용자 payload를 반환합니다.
  /// credential/cookie 세부 처리는 Gateway 구현에 격리됩니다.
  /// Parameters:
  /// - [payload]: Mapper가 만든 login 요청 payload입니다.
  /// Returns:
  /// - [result]: Gateway가 정규화한 인증 사용자 payload입니다.
  Future<Map<String, Object?>> login(Map<String, Object?> payload);

  /// 현재 인증 사용자를 조회합니다.
  /// 세션 방식이 바뀌어도 Controller는 [AdminService] 계약만 사용합니다.
  /// 인증되지 않은 401/403 응답은 예외가 아니라 null session으로 정규화합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: Gateway가 정규화한 현재 사용자 payload이거나 비로그인 상태의 null입니다.
  Future<Map<String, Object?>?> me();

  /// 현재 인증 세션을 종료합니다.
  /// body 없는 성공 응답도 Gateway 구현에서 허용합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> logout();

  /// 관리자 vote 목록 payload를 조회합니다.
  /// Mapper가 이 결과를 [AdminVote] 목록으로 변환합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: vote payload 목록입니다.
  Future<List<Map<String, Object?>>> fetchVotes();

  /// vote 생성 API를 호출합니다.
  /// 생성 endpoint 경로는 구현체 설정에서 흡수합니다.
  /// Parameters:
  /// - [payload]: Mapper가 만든 vote 생성 payload입니다.
  /// Returns:
  /// - [result]: 생성된 vote payload입니다.
  Future<Map<String, Object?>> createVote(Map<String, Object?> payload);

  /// 단일 vote payload를 조회합니다.
  /// path segment encoding은 Gateway 구현이 담당합니다.
  /// Parameters:
  /// - [voteId]: 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: vote 상세 payload입니다.
  Future<Map<String, Object?>> fetchVote(String voteId);

  /// vote update API를 호출합니다.
  /// payload field 구성은 Mapper가, endpoint/path는 Gateway가 책임집니다.
  /// Parameters:
  /// - [voteId]: 수정할 vote 식별자입니다.
  /// - [payload]: Mapper가 만든 vote update payload입니다.
  /// Returns:
  /// - [result]: 수정된 vote payload입니다.
  Future<Map<String, Object?>> updateVote({
    required String voteId,
    required Map<String, Object?> payload,
  });

  /// vote delete API를 호출합니다.
  /// Controller는 삭제 endpoint를 직접 보유하지 않습니다.
  /// Parameters:
  /// - [voteId]: 삭제할 vote 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> deleteVote(String voteId);

  /// vote에 속한 question payload 목록을 조회합니다.
  /// Mapper가 결과를 [AdminQuestion] 목록으로 변환합니다.
  /// Parameters:
  /// - [voteId]: question 목록을 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: question payload 목록입니다.
  Future<List<Map<String, Object?>>> fetchQuestions(String voteId);

  /// question 생성 API를 호출합니다.
  /// 이미지 bytes는 포함하지 않고 Mapper가 만든 URL/ratio payload만 전달됩니다.
  /// Parameters:
  /// - [payload]: Mapper가 만든 question 생성 payload입니다.
  /// Returns:
  /// - [result]: 생성된 question payload입니다.
  Future<Map<String, Object?>> createQuestion(Map<String, Object?> payload);

  /// question update API를 호출합니다.
  /// path encoding과 HTTP method 선택은 Gateway 구현에 격리됩니다.
  /// Parameters:
  /// - [questionId]: 수정할 question 식별자입니다.
  /// - [payload]: Mapper가 만든 question update payload입니다.
  /// Returns:
  /// - [result]: 수정된 question payload입니다.
  Future<Map<String, Object?>> updateQuestion({
    required String questionId,
    required Map<String, Object?> payload,
  });

  /// question delete API를 호출합니다.
  /// View와 Controller는 generated client나 endpoint 문자열을 알지 않습니다.
  /// Parameters:
  /// - [questionId]: 삭제할 question 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> deleteQuestion(String questionId);

  /// public vote display payload를 조회합니다.
  /// player와 participant 공개 데이터 확인 흐름에서 Service를 통해 호출됩니다.
  /// Parameters:
  /// - [voteId]: 공개 display를 확인할 vote 식별자입니다.
  /// Returns:
  /// - [result]: public vote display payload입니다.
  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId);

  /// public question payload 목록을 조회합니다.
  /// player가 읽을 question 데이터 존재 여부를 확인하는 데 사용됩니다.
  /// Parameters:
  /// - [voteId]: 공개 question 목록을 확인할 vote 식별자입니다.
  /// Returns:
  /// - [result]: public question payload 목록입니다.
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId);
}

/// Dio 기반 Tagvote 관리자 API Gateway 구현입니다.
/// 직접 endpoint 호출은 이 파일에 모아두며, generated client로 교체해도 Controller/View는 바뀌지 않습니다.
/// JSON content-type과 debug logging 정책도 Gateway 경계에서 처리합니다.
/// fields:
/// - [defaultBaseUrl]: 기본 API base URL 설정입니다.
/// - [defaultVoteCreatePath]: 현재 서버에 맞춘 기본 vote 생성 경로입니다.
/// - [_dio]: API 호출과 interceptor를 보유한 Dio client입니다.
/// - [_voteCreatePath]: 환경별 vote 생성 endpoint 경로입니다.
class DioAdminApiGateway implements AdminApiGateway {
  /// Dio Gateway를 생성합니다.
  /// 외부 Dio가 없으면 base URL, timeout, credential 설정을 포함한 client를 구성합니다.
  /// Parameters:
  /// - [dio]: 테스트나 커스텀 실행에서 주입할 Dio client입니다.
  /// - [baseUrl]: API base URL입니다.
  /// - [voteCreatePath]: vote 생성 endpoint 경로입니다.
  /// - [withCredentials]: browser credential 전송 여부입니다.
  /// Returns:
  /// - [instance]: Dio 기반 API Gateway 인스턴스입니다.
  DioAdminApiGateway({
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    String voteCreatePath = defaultVoteCreatePath,
    bool withCredentials = true,
  }) : _dio = _withGatewayInterceptors(
         dio ?? _createDio(baseUrl: baseUrl, withCredentials: withCredentials),
       ),
       _voteCreatePath = voteCreatePath;

  /// real API 호출의 기본 base URL입니다.
  /// 비밀 값이 아닌 운영 설정이며 dart-define으로 대체할 수 있습니다.
  static const defaultBaseUrl = 'https://vote.newdawnsoi.site';

  /// vote 생성 API의 기본 경로입니다.
  /// 로그인 사용자 보호 endpoint가 확정되면 설정값만 교체하도록 분리되어 있습니다.
  static const defaultVoteCreatePath = '/api/public/votes';

  static const _suppressExpectedAuthFailureLog =
      'suppressExpectedAuthFailureLog';
  static const _withCredentialsExtra = 'withCredentials';

  /// 실제 HTTP 요청을 수행하는 Dio client입니다.
  /// browser credential과 Gateway interceptor 설정을 포함합니다.
  final Dio _dio;

  /// vote 생성 요청에 사용할 endpoint 경로입니다.
  /// 서버 contract 변화를 View/Controller 대신 Gateway 설정에서 흡수합니다.
  final String _voteCreatePath;

  /// 회원가입 요청을 서버에 전송합니다.
  /// 응답 body는 사용자 object payload로 정규화됩니다.
  /// Parameters:
  /// - [payload]: signup 요청 payload입니다.
  /// Returns:
  /// - [result]: 생성된 사용자 payload입니다.
  @override
  Future<Map<String, Object?>> signup(Map<String, Object?> payload) async {
    final response = await _dio.post<Object?>('/api/users', data: payload);
    return _asPayload(response.data, 'created user');
  }

  /// 로그인 요청을 서버에 전송합니다.
  /// debug interceptor는 로그인 응답/오류 data를 redaction합니다.
  /// Parameters:
  /// - [payload]: login 요청 payload입니다.
  /// Returns:
  /// - [result]: 인증 사용자 payload입니다.
  @override
  Future<Map<String, Object?>> login(Map<String, Object?> payload) async {
    try {
      final response = await _dio.post<Object?>(
        '/api/auth/login',
        data: payload,
      );
      return _asPayload(response.data, 'auth user');
    } on DioException catch (error, stackTrace) {
      _throwLoginException(error, stackTrace);
    }
  }

  /// 현재 인증 사용자 payload를 조회합니다.
  /// 세션 cookie 전송 여부는 Dio adapter 설정을 따릅니다.
  /// 비로그인 상태의 401/403은 앱 시작 흐름에서 정상적인 null session으로 처리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 현재 사용자 payload이거나 비로그인 상태의 null입니다.
  @override
  Future<Map<String, Object?>?> me() async {
    final response = await _dio.get<Object?>(
      '/api/auth/me',
      options: Options(
        extra: const <String, dynamic>{_suppressExpectedAuthFailureLog: true},
        validateStatus: (status) {
          return status != null &&
              (status < 400 || status == 401 || status == 403);
        },
      ),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      return null;
    }
    return _asPayload(response.data, 'current auth user');
  }

  /// 로그아웃 요청을 서버에 전송합니다.
  /// 응답 body를 사용하지 않고 완료 여부만 Service에 전달합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> logout() async {
    await _dio.post<Object?>('/api/auth/logout');
  }

  /// 관리자 vote 목록을 조회합니다.
  /// 응답 data는 map 목록이어야 하며 아니면 format 오류를 발생시킵니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: vote payload 목록입니다.
  @override
  Future<List<Map<String, Object?>>> fetchVotes() async {
    final response = await _dio.get<Object?>('/api/votes');
    return _asPayloadList(response.data, 'vote list');
  }

  /// vote 생성 요청을 전송합니다.
  /// 생성 경로는 [voteCreatePath] 설정으로 교체할 수 있습니다.
  /// Parameters:
  /// - [payload]: vote 생성 payload입니다.
  /// Returns:
  /// - [result]: 생성된 vote payload입니다.
  @override
  Future<Map<String, Object?>> createVote(Map<String, Object?> payload) async {
    final response = await _dio.post<Object?>(
      _voteCreatePath,
      data: payload,
      options: _voteCreateOptions(),
    );
    return _asPayload(response.data, 'created vote');
  }

  /// 단일 vote 상세 payload를 조회합니다.
  /// voteId는 path segment로 안전하게 encode됩니다.
  /// Parameters:
  /// - [voteId]: 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: vote 상세 payload입니다.
  @override
  Future<Map<String, Object?>> fetchVote(String voteId) async {
    final response = await _dio.get<Object?>('/api/votes/${_path(voteId)}');
    return _asPayload(response.data, 'vote detail');
  }

  /// vote 수정 요청을 전송합니다.
  /// Mapper가 만든 payload를 그대로 전달하고 응답을 object payload로 정규화합니다.
  /// Parameters:
  /// - [voteId]: 수정할 vote 식별자입니다.
  /// - [payload]: vote update payload입니다.
  /// Returns:
  /// - [result]: 수정된 vote payload입니다.
  @override
  Future<Map<String, Object?>> updateVote({
    required String voteId,
    required Map<String, Object?> payload,
  }) async {
    final response = await _dio.patch<Object?>(
      '/api/votes/${_path(voteId)}',
      data: payload,
    );
    return _asPayload(response.data, 'updated vote');
  }

  /// vote 삭제 요청을 전송합니다.
  /// 성공 시 반환 payload 없이 완료됩니다.
  /// Parameters:
  /// - [voteId]: 삭제할 vote 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> deleteVote(String voteId) async {
    await _dio.delete<Object?>('/api/votes/${_path(voteId)}');
  }

  /// vote 하위 question 목록 payload를 조회합니다.
  /// 응답 list 정규화 실패는 Mapper가 아니라 Gateway format 오류로 처리합니다.
  /// Parameters:
  /// - [voteId]: question 목록을 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: question payload 목록입니다.
  @override
  Future<List<Map<String, Object?>>> fetchQuestions(String voteId) async {
    final response = await _dio.get<Object?>(
      '/api/votes/${_path(voteId)}/questions',
    );
    return _asPayloadList(response.data, 'question list');
  }

  /// question 생성 요청을 전송합니다.
  /// payload에는 imageUrl과 imageRatio만 포함되고 image bytes는 포함하지 않습니다.
  /// Parameters:
  /// - [payload]: question 생성 payload입니다.
  /// Returns:
  /// - [result]: 생성된 question payload입니다.
  @override
  Future<Map<String, Object?>> createQuestion(
    Map<String, Object?> payload,
  ) async {
    final response = await _dio.post<Object?>('/api/questions', data: payload);
    return _asPayload(response.data, 'created question');
  }

  /// question 수정 요청을 전송합니다.
  /// questionId는 path segment로 encode되어 endpoint에 포함됩니다.
  /// Parameters:
  /// - [questionId]: 수정할 question 식별자입니다.
  /// - [payload]: question update payload입니다.
  /// Returns:
  /// - [result]: 수정된 question payload입니다.
  @override
  Future<Map<String, Object?>> updateQuestion({
    required String questionId,
    required Map<String, Object?> payload,
  }) async {
    final response = await _dio.patch<Object?>(
      '/api/questions/${_path(questionId)}',
      data: payload,
    );
    return _asPayload(response.data, 'updated question');
  }

  /// question 삭제 요청을 전송합니다.
  /// 성공 시 반환 payload 없이 완료됩니다.
  /// Parameters:
  /// - [questionId]: 삭제할 question 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> deleteQuestion(String questionId) async {
    await _dio.delete<Object?>('/api/questions/${_path(questionId)}');
  }

  /// public vote display payload를 조회합니다.
  /// 운영 미리보기와 player 데이터 존재 확인에서 사용됩니다.
  /// Parameters:
  /// - [voteId]: 공개 display를 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: public vote display payload입니다.
  @override
  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId) async {
    final response = await _dio.get<Object?>(
      '/api/public/votes/${_path(voteId)}/display',
    );
    return _asPayload(response.data, 'public vote display');
  }

  /// public question payload 목록을 조회합니다.
  /// player/participant 공개 화면에서 읽을 question 데이터를 확인합니다.
  /// Parameters:
  /// - [voteId]: 공개 question 목록을 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: public question payload 목록입니다.
  @override
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId) async {
    final response = await _dio.get<Object?>(
      '/api/public/votes/${_path(voteId)}/questions',
    );
    return _asPayloadList(response.data, 'public question list');
  }

  /// Gateway에 필요한 Dio interceptor를 중복 없이 추가합니다.
  /// JSON body header 정책과 debug logging 정책을 Gateway 경계에 묶어 둡니다.
  /// Parameters:
  /// - [dio]: interceptor를 적용할 Dio client입니다.
  /// Returns:
  /// - [result]: Gateway interceptor가 적용된 Dio client입니다.
  static Dio _withGatewayInterceptors(Dio dio) {
    if (!dio.interceptors.any(
      (interceptor) => interceptor is _JsonContentTypeInterceptor,
    )) {
      dio.interceptors.add(_JsonContentTypeInterceptor());
    }
    if (!dio.interceptors.any(
      (interceptor) => interceptor is _AdminApiDebugLogInterceptor,
    )) {
      dio.interceptors.add(_AdminApiDebugLogInterceptor());
    }
    return dio;
  }

  /// 기본 Dio client를 생성합니다.
  /// base URL, timeout, Accept header, browser credential adapter를 함께 구성합니다.
  /// Parameters:
  /// - [baseUrl]: API base URL입니다.
  /// - [withCredentials]: browser credential 전송 여부입니다.
  /// Returns:
  /// - [result]: Gateway 호출에 사용할 Dio client입니다.
  static Dio _createDio({
    required String baseUrl,
    required bool withCredentials,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const <String, Object?>{'Accept': 'application/json'},
      ),
    );
    configureAdminDioAdapter(dio, withCredentials: withCredentials);
    return dio;
  }

  /// path segment에 들어갈 id를 URL 안전 문자열로 변환합니다.
  /// voteId/questionId에 특수 문자가 있어도 endpoint path가 깨지지 않게 합니다.
  /// Parameters:
  /// - [id]: path segment로 사용할 식별자입니다.
  /// Returns:
  /// - [result]: URL encode된 path segment입니다.
  String _path(String id) => Uri.encodeComponent(id);

  /// vote 생성 요청에 사용할 per-request option을 계산합니다.
  /// 현재 임시 public 생성 endpoint는 credentialed CORS 응답을 내려주지 않으므로 cookie 전송을 끕니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: public 임시 endpoint 전용 credential override 또는 기본 null입니다.
  Options? _voteCreateOptions() {
    if (_voteCreatePath != defaultVoteCreatePath) {
      return null;
    }
    return Options(
      extra: const <String, dynamic>{_withCredentialsExtra: false},
    );
  }

  /// 응답 data를 object payload map으로 정규화합니다.
  /// 예상 구조가 아니면 Mapper에 잘못된 형태가 전달되지 않도록 format 오류를 냅니다.
  /// Parameters:
  /// - [data]: Dio 응답 body입니다.
  /// - [fieldName]: 오류 메시지에 사용할 payload 설명입니다.
  /// Returns:
  /// - [result]: 문자열 key를 가진 payload map입니다.
  Map<String, Object?> _asPayload(Object? data, String fieldName) {
    if (data is Map<String, Object?>) {
      return data;
    }
    if (data is Map) {
      return data.map<String, Object?>(
        (key, dynamic value) =>
            MapEntry<String, Object?>(key.toString(), value as Object?),
      );
    }
    throw FormatException('Expected $fieldName to be an object');
  }

  /// 응답 data를 object payload map 목록으로 정규화합니다.
  /// list 내부 항목도 [_asPayload]를 통해 문자열 key map으로 맞춥니다.
  /// Parameters:
  /// - [data]: Dio 응답 body입니다.
  /// - [fieldName]: 오류 메시지에 사용할 payload 설명입니다.
  /// Returns:
  /// - [result]: payload map 목록입니다.
  List<Map<String, Object?>> _asPayloadList(Object? data, String fieldName) {
    if (data is Iterable) {
      return data
          .map((item) => _asPayload(item, fieldName))
          .toList(growable: false);
    }
    throw FormatException('Expected $fieldName to be a list');
  }

  /// 로그인 실패 응답을 화면에 보여줄 수 있는 안전한 오류로 바꿉니다.
  /// 비밀번호나 서버 payload는 포함하지 않고 인증 실패 원인만 일반화합니다.
  /// Parameters:
  /// - [error]: Dio에서 받은 로그인 실패 예외입니다.
  /// - [stackTrace]: 원래 실패 지점의 stack trace입니다.
  /// Returns:
  /// - [never]: 항상 [AdminApiException]을 던집니다.
  Never _throwLoginException(DioException error, StackTrace stackTrace) {
    final statusCode = error.response?.statusCode;
    final message = switch (statusCode) {
      401 || 403 => '아이디 또는 비밀번호를 확인해주세요.',
      null => '관리자 배포 origin 또는 서버 CORS 설정을 확인해주세요.',
      >= 500 => '서버 오류입니다. 잠시 후 다시 시도해주세요.',
      _ => '로그인에 실패했습니다.',
    };
    Error.throwWithStackTrace(
      AdminApiException(message, statusCode: statusCode),
      stackTrace,
    );
  }
}

/// 관리자 API 실패를 View에 노출 가능한 메시지로 정규화한 예외입니다.
/// 민감한 request/response payload는 보관하지 않고 status와 안전한 문구만 전달합니다.
/// fields:
/// - [message]: 사용자에게 표시할 수 있는 오류 메시지입니다.
/// - [statusCode]: 서버가 응답한 HTTP status이며 네트워크 실패면 null입니다.
class AdminApiException implements Exception {
  /// API 예외 값을 생성합니다.
  /// Parameters:
  /// - [message]: 안전하게 표시할 오류 메시지입니다.
  /// - [statusCode]: 선택적 HTTP status code입니다.
  /// Returns:
  /// - [instance]: 관리자 API 예외 인스턴스입니다.
  const AdminApiException(this.message, {this.statusCode});

  /// 사용자에게 표시할 수 있는 오류 메시지입니다.
  final String message;

  /// 서버 응답 status code입니다. CORS/네트워크 실패처럼 응답이 없으면 null입니다.
  final int? statusCode;

  /// Controller의 일반 오류 메시지 정규화에서 안전한 메시지만 사용되게 합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 사용자 표시용 메시지입니다.
  @override
  String toString() => message;
}

/// body가 있는 JSON 요청에만 content-type을 추가하는 Dio interceptor입니다.
/// bodyless GET에 JSON content-type을 붙이지 않는 Gateway 정책을 지킵니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class _JsonContentTypeInterceptor extends Interceptor {
  /// 요청 body와 기존 header를 확인해 JSON content-type을 보강합니다.
  /// Dio handler로 요청 흐름을 계속 넘기는 부수 효과만 수행합니다.
  /// Parameters:
  /// - [options]: Dio 요청 설정입니다.
  /// - [handler]: 다음 interceptor로 요청을 넘기는 handler입니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isJsonBody(options.data) &&
        !_hasHeader(options.headers, Headers.contentTypeHeader)) {
      options.headers[Headers.contentTypeHeader] = Headers.jsonContentType;
    }
    handler.next(options);
  }

  /// 요청 body가 JSON content-type을 요구하는 구조인지 판단합니다.
  /// map과 iterable body만 JSON body로 취급합니다.
  /// Parameters:
  /// - [data]: Dio 요청 body입니다.
  /// Returns:
  /// - [result]: JSON content-type 보강 필요 여부입니다.
  bool _isJsonBody(Object? data) {
    return data is Map || data is Iterable;
  }

  /// header map에 특정 header가 이미 있는지 대소문자 구분 없이 확인합니다.
  /// 호출자가 명시한 content-type을 Gateway가 덮어쓰지 않도록 보호합니다.
  /// Parameters:
  /// - [headers]: Dio 요청 header map입니다.
  /// - [name]: 확인할 header 이름입니다.
  /// Returns:
  /// - [result]: 해당 header 존재 여부입니다.
  bool _hasHeader(Map<String, dynamic> headers, String name) {
    return headers.keys.any((key) => key.toLowerCase() == name.toLowerCase());
  }
}

/// debug build에서 관리자 API 응답과 오류를 요약 출력하는 interceptor입니다.
/// 로그인 payload는 redaction해 민감한 인증 데이터가 로그에 남지 않게 합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class _AdminApiDebugLogInterceptor extends Interceptor {
  /// 성공 응답을 debug log로 기록한 뒤 interceptor 체인을 진행합니다.
  /// release build에서는 출력하지 않습니다.
  /// Parameters:
  /// - [response]: Dio 성공 응답입니다.
  /// - [handler]: 다음 interceptor로 응답을 넘기는 handler입니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _debugPrintResponse(response);
    handler.next(response);
  }

  /// 오류 응답을 debug log로 기록한 뒤 interceptor 체인을 진행합니다.
  /// 네트워크 오류와 응답 포함 오류를 구분해 출력합니다.
  /// Parameters:
  /// - [err]: Dio 오류 객체입니다.
  /// - [handler]: 다음 interceptor로 오류를 넘기는 handler입니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _debugPrintError(err);
    handler.next(err);
  }

  /// 성공 응답의 method, URL, status, data 요약을 debug 출력합니다.
  /// 긴 data는 [_debugData]에서 자르며 release build에서는 아무 것도 하지 않습니다.
  /// Parameters:
  /// - [response]: 출력할 Dio 성공 응답입니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  void _debugPrintResponse(Response<dynamic> response) {
    if (!kDebugMode) {
      return;
    }
    if (_isExpectedAuthFailure(response)) {
      return;
    }

    final options = response.requestOptions;
    debugPrint(
      '[Taglow Admin API] RESPONSE ${options.method} ${options.uri} '
      'status=${response.statusCode} data=${_debugData(options, response.data)}',
    );
  }

  /// 비로그인 상태에서 앱 시작 세션 확인이 반환하는 401/403 로그인지 확인합니다.
  /// 이 실패는 Controller가 null session으로 처리하므로 debug error noise에서 제외합니다.
  /// Parameters:
  /// - [response]: Dio 응답입니다.
  /// Returns:
  /// - [result]: 예상된 세션 확인 실패 여부입니다.
  bool _isExpectedAuthFailure(Response<dynamic> response) {
    final statusCode = response.statusCode;
    return response.requestOptions.extra[DioAdminApiGateway
                ._suppressExpectedAuthFailureLog] ==
            true &&
        (statusCode == 401 || statusCode == 403);
  }

  /// 실패 응답의 method, URL, status, type, data 요약을 debug 출력합니다.
  /// 응답이 없는 네트워크 오류는 별도 형식으로 출력합니다.
  /// Parameters:
  /// - [err]: 출력할 Dio 오류 객체입니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  void _debugPrintError(DioException err) {
    if (!kDebugMode) {
      return;
    }

    final options = err.requestOptions;
    final response = err.response;
    if (response == null) {
      debugPrint(
        '[Taglow Admin API] ERROR ${options.method} ${options.uri} '
        'type=${err.type} message=${err.message}',
      );
      return;
    }

    debugPrint(
      '[Taglow Admin API] ERROR ${options.method} ${options.uri} '
      'status=${response.statusCode} type=${err.type} '
      'data=${_debugData(options, response.data)}',
    );
  }

  /// debug log에 넣을 response data를 안전한 문자열로 만듭니다.
  /// 로그인 endpoint data는 redaction하고 긴 응답은 길이 제한으로 잘라냅니다.
  /// Parameters:
  /// - [options]: 응답을 만든 요청 설정입니다.
  /// - [data]: 출력 대상 응답 data입니다.
  /// Returns:
  /// - [result]: debug log에 기록할 안전한 data 요약 문자열입니다.
  String _debugData(RequestOptions options, Object? data) {
    if (options.path == '/api/auth/login') {
      return '<redacted>';
    }

    final text = data?.toString() ?? 'null';
    const maxLength = 4000;
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}... <truncated ${text.length} chars>';
  }
}
