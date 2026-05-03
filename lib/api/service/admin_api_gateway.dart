import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'admin_dio_adapter_stub.dart'
    if (dart.library.html) 'admin_dio_adapter_web.dart';

/// Low-level gateway that returns normalized admin API payloads.
///
/// Endpoint paths, headers, credentials, Dio/generated-client calls, and raw
/// server payload differences should stay behind this adapter.
abstract class AdminApiGateway {
  Future<Map<String, Object?>> login(Map<String, Object?> payload);
  Future<Map<String, Object?>> me();
  Future<void> logout();

  Future<List<Map<String, Object?>>> fetchVotes();
  Future<Map<String, Object?>> createVote(Map<String, Object?> payload);
  Future<Map<String, Object?>> fetchVote(String voteId);
  Future<Map<String, Object?>> updateVote({
    required String voteId,
    required Map<String, Object?> payload,
  });
  Future<void> deleteVote(String voteId);

  Future<List<Map<String, Object?>>> fetchQuestions(String voteId);
  Future<Map<String, Object?>> createQuestion(Map<String, Object?> payload);
  Future<Map<String, Object?>> updateQuestion({
    required String questionId,
    required Map<String, Object?> payload,
  });
  Future<void> deleteQuestion(String questionId);

  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId);
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId);
}

/// Tagvote admin API gateway backed by Dio.
///
/// OpenAPI generated client calls can replace the direct endpoint calls here
/// without changing controllers, views, or [OpenApiAdminService].
class DioAdminApiGateway implements AdminApiGateway {
  DioAdminApiGateway({
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    String voteCreatePath = defaultVoteCreatePath,
    bool withCredentials = true,
  }) : _dio = _withGatewayInterceptors(
         dio ?? _createDio(baseUrl: baseUrl, withCredentials: withCredentials),
       ),
       _voteCreatePath = voteCreatePath;

  static const defaultBaseUrl = 'https://vote.newdawnsoi.site';
  static const defaultVoteCreatePath = '/api/public/votes';

  final Dio _dio;
  final String _voteCreatePath;

  @override
  Future<Map<String, Object?>> login(Map<String, Object?> payload) async {
    final response = await _dio.post<Object?>('/api/auth/login', data: payload);
    return _asPayload(response.data, 'auth user');
  }

  @override
  Future<Map<String, Object?>> me() async {
    final response = await _dio.get<Object?>('/api/auth/me');
    return _asPayload(response.data, 'current auth user');
  }

  @override
  Future<void> logout() async {
    await _dio.post<Object?>('/api/auth/logout');
  }

  @override
  Future<List<Map<String, Object?>>> fetchVotes() async {
    final response = await _dio.get<Object?>('/api/votes');
    return _asPayloadList(response.data, 'vote list');
  }

  @override
  Future<Map<String, Object?>> createVote(Map<String, Object?> payload) async {
    final response = await _dio.post<Object?>(_voteCreatePath, data: payload);
    return _asPayload(response.data, 'created vote');
  }

  @override
  Future<Map<String, Object?>> fetchVote(String voteId) async {
    final response = await _dio.get<Object?>('/api/votes/${_path(voteId)}');
    return _asPayload(response.data, 'vote detail');
  }

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

  @override
  Future<void> deleteVote(String voteId) async {
    await _dio.delete<Object?>('/api/votes/${_path(voteId)}');
  }

  @override
  Future<List<Map<String, Object?>>> fetchQuestions(String voteId) async {
    final response = await _dio.get<Object?>(
      '/api/votes/${_path(voteId)}/questions',
    );
    return _asPayloadList(response.data, 'question list');
  }

  @override
  Future<Map<String, Object?>> createQuestion(
    Map<String, Object?> payload,
  ) async {
    final response = await _dio.post<Object?>('/api/questions', data: payload);
    return _asPayload(response.data, 'created question');
  }

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

  @override
  Future<void> deleteQuestion(String questionId) async {
    await _dio.delete<Object?>('/api/questions/${_path(questionId)}');
  }

  @override
  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId) async {
    final response = await _dio.get<Object?>(
      '/api/public/votes/${_path(voteId)}/display',
    );
    return _asPayload(response.data, 'public vote display');
  }

  @override
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId) async {
    final response = await _dio.get<Object?>(
      '/api/public/votes/${_path(voteId)}/questions',
    );
    return _asPayloadList(response.data, 'public question list');
  }

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

  String _path(String id) => Uri.encodeComponent(id);

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

  List<Map<String, Object?>> _asPayloadList(Object? data, String fieldName) {
    if (data is Iterable) {
      return data
          .map((item) => _asPayload(item, fieldName))
          .toList(growable: false);
    }
    throw FormatException('Expected $fieldName to be a list');
  }
}

class _JsonContentTypeInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isJsonBody(options.data) &&
        !_hasHeader(options.headers, Headers.contentTypeHeader)) {
      options.headers[Headers.contentTypeHeader] = Headers.jsonContentType;
    }
    handler.next(options);
  }

  bool _isJsonBody(Object? data) {
    return data is Map || data is Iterable;
  }

  bool _hasHeader(Map<String, dynamic> headers, String name) {
    return headers.keys.any((key) => key.toLowerCase() == name.toLowerCase());
  }
}

class _AdminApiDebugLogInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _debugPrintResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _debugPrintError(err);
    handler.next(err);
  }

  void _debugPrintResponse(Response<dynamic> response) {
    if (!kDebugMode) {
      return;
    }

    final options = response.requestOptions;
    debugPrint(
      '[Taglow Admin API] RESPONSE ${options.method} ${options.uri} '
      'status=${response.statusCode} data=${_debugData(options, response.data)}',
    );
  }

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
