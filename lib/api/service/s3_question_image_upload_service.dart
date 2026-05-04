import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../model/question_image_upload_result.dart';
import '../../utils/image_ratio_reader.dart';
import 'question_image_upload_service.dart';

/// Cognito 임시 자격 증명으로 question 이미지를 S3에 직접 업로드하는 service입니다.
/// 장기 AWS key를 프런트엔드에 저장하지 않고 Identity Pool에서 받은 단기 credential로 PUT 요청을 서명합니다.
/// fields:
/// - [identityPoolId]: Cognito Identity Pool 식별자입니다.
/// - [bucket]: 업로드 대상 S3 bucket 이름입니다.
/// - [region]: Cognito와 S3가 위치한 AWS region입니다.
/// - [publicBaseUrl]: 업로드 결과 public URL 생성 기준 base URL입니다.
/// - [questionImagePrefix]: question 이미지 object key prefix입니다.
/// - [_debugLogsEnabled]: S3 업로드 debug log 출력 여부입니다.
class S3QuestionImageUploadService implements QuestionImageUploadService {
  /// S3 직접 업로드 service를 생성합니다.
  /// Parameters:
  /// - [identityPoolId]: Cognito Identity Pool 식별자입니다.
  /// - [bucket]: 업로드 대상 S3 bucket 이름입니다.
  /// - [region]: AWS region입니다.
  /// - [publicBaseUrl]: 공개 이미지 URL base입니다.
  /// - [questionImagePrefix]: question 이미지 저장 prefix입니다.
  /// - [dio]: 테스트나 커스텀 실행에서 주입할 Dio client입니다.
  /// - [now]: 서명 시각을 테스트에서 고정하기 위한 clock입니다.
  /// - [nonce]: object key 충돌 방지 값을 테스트에서 고정하기 위한 함수입니다.
  /// - [debugLogsEnabled]: S3 업로드 debug log 출력 여부입니다.
  /// Returns:
  /// - [instance]: S3 question 이미지 업로드 service입니다.
  S3QuestionImageUploadService({
    required this.identityPoolId,
    required this.bucket,
    required this.region,
    required this.publicBaseUrl,
    this.questionImagePrefix = 'public/question-images',
    Dio? dio,
    DateTime Function()? now,
    String Function()? nonce,
    ImageRatioReader ratioReader = const ImageRatioReader(),
    bool? debugLogsEnabled,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(seconds: 30),
               sendTimeout: const Duration(seconds: 30),
             ),
           ),
       _now = now ?? DateTime.now,
       _nonce = nonce ?? _randomNonce,
       _ratioReader = ratioReader,
       _debugLogsEnabled = debugLogsEnabled ?? (kDebugMode || _forceDebugLogs);

  /// Cognito Identity Pool 식별자입니다.
  /// 비밀 값은 아니지만 S3 업로드 권한 범위를 결정하는 운영 설정입니다.
  final String identityPoolId;

  /// 업로드 대상 S3 bucket 이름입니다.
  final String bucket;

  /// Cognito와 S3가 위치한 AWS region입니다.
  final String region;

  /// 공개 이미지 URL을 만들 때 사용할 base URL입니다.
  final String publicBaseUrl;

  /// question 이미지 object key prefix입니다.
  final String questionImagePrefix;

  final Dio _dio;
  final DateTime Function() _now;
  final String Function() _nonce;
  final ImageRatioReader _ratioReader;
  final bool _debugLogsEnabled;

  static const bool _forceDebugLogs = bool.fromEnvironment(
    'TAGLOW_ENABLE_S3_DEBUG_LOGS',
  );
  static const String _awsJsonContentType = 'application/x-amz-json-1.1';
  static const String _getIdTarget =
      'com.amazonaws.cognito.identity.model.AWSCognitoIdentityService.GetId';
  static const String _getCredentialsTarget =
      'com.amazonaws.cognito.identity.model.'
      'AWSCognitoIdentityService.GetCredentialsForIdentity';

  /// question 이미지를 S3에 PUT하고 공개 URL과 imageRatio를 반환합니다.
  /// Cognito GetId/GetCredentialsForIdentity 요청 후 AWS SigV4로 S3 PUT 요청을 서명합니다.
  /// Parameters:
  /// - [bytes]: 업로드할 이미지 byte 목록입니다.
  /// - [fileName]: 원본 파일명입니다.
  /// - [contentType]: 이미지 MIME type입니다.
  /// - [imageWidth]: 원본 이미지 가로 픽셀입니다.
  /// - [imageHeight]: 원본 이미지 세로 픽셀입니다.
  /// Returns:
  /// - [result]: 업로드된 이미지의 public URL과 ratio 결과입니다.
  @override
  Future<QuestionImageUploadResult> uploadQuestionImage({
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required int imageWidth,
    required int imageHeight,
  }) async {
    _debugPrint(
      'UPLOAD START fileName=${_debugFileName(fileName)} '
      'contentType=$contentType sizeBytes=${bytes.length} '
      'dimensions=${imageWidth}x$imageHeight '
      'bucket=${bucket.trim()} region=${region.trim()} '
      'prefix=${_trimSlashes(questionImagePrefix)}',
    );
    _validateConfig();
    _validateUploadInput(
      bytes: bytes,
      contentType: contentType,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );

    try {
      final identityId = await _requestIdentityId();
      final credentials = await _requestCredentials(identityId);
      final now = _now().toUtc();
      final objectKey = _buildObjectKey(
        identityId: identityId,
        fileName: fileName,
        contentType: contentType,
        now: now,
      );
      _debugPrint(
        'OBJECT KEY READY key=${_redactObjectKey(objectKey)} '
        'identityId=${_redactIdentityId(identityId)}',
      );
      await _putObject(
        objectKey: objectKey,
        bytes: Uint8List.fromList(bytes),
        contentType: contentType,
        credentials: credentials,
        now: now,
      );
      _debugPrint(
        'UPLOAD COMPLETE key=${_redactObjectKey(objectKey)} '
        'publicBaseUrl=${_trimTrailingSlash(publicBaseUrl)}',
      );

      return QuestionImageUploadResult(
        objectKey: objectKey,
        publicUrl:
            '${_trimTrailingSlash(publicBaseUrl)}/${_encodeKey(objectKey)}',
        contentType: contentType,
        sizeBytes: bytes.length,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        imageRatio: _ratioReader.fromDimensions(
          width: imageWidth,
          height: imageHeight,
        ),
      );
    } on QuestionImageUploadException {
      rethrow;
    } on DioException catch (error) {
      _debugPrintDioError('UPLOAD ERROR', error);
      throw const QuestionImageUploadException(
        '이미지 업로드에 실패했습니다. S3/Cognito CORS와 권한 설정을 확인해주세요.',
      );
    } catch (error) {
      _debugPrint('UPLOAD ERROR type=${error.runtimeType} message=$error');
      throw const QuestionImageUploadException('이미지 업로드에 실패했습니다.');
    }
  }

  Future<String> _requestIdentityId() async {
    _debugPrint(
      'COGNITO GetId REQUEST uri=$_cognitoUri '
      'identityPoolId=${_redactIdentityPoolId(identityPoolId)}',
    );
    late final Response<String> response;
    try {
      response = await _dio.postUri<String>(
        _cognitoUri,
        data: <String, Object?>{'IdentityPoolId': identityPoolId.trim()},
        options: Options(
          headers: const <String, Object?>{
            'Content-Type': _awsJsonContentType,
            'X-Amz-Target': _getIdTarget,
          },
          responseType: ResponseType.plain,
          validateStatus: _isSuccessStatus,
        ),
      );
    } on DioException catch (error) {
      _debugPrintDioError('COGNITO GetId ERROR', error);
      rethrow;
    }
    final data = _asMap(response.data);
    final identityId = data['IdentityId'];
    if (identityId is! String || identityId.trim().isEmpty) {
      _debugPrint(
        'COGNITO GetId ERROR missing IdentityId '
        'status=${response.statusCode} keys=${_debugMapKeys(data)} '
        'awsError=${_debugAwsError(data)}',
      );
      throw const QuestionImageUploadException(
        'Cognito Identity 응답을 확인하지 못했습니다.',
      );
    }
    _debugPrint(
      'COGNITO GetId RESPONSE status=${response.statusCode} '
      'identityId=${_redactIdentityId(identityId)}',
    );
    return identityId;
  }

  Future<_CognitoCredentials> _requestCredentials(String identityId) async {
    _debugPrint(
      'COGNITO Credentials REQUEST uri=$_cognitoUri '
      'identityId=${_redactIdentityId(identityId)}',
    );
    late final Response<String> response;
    try {
      response = await _dio.postUri<String>(
        _cognitoUri,
        data: <String, Object?>{'IdentityId': identityId},
        options: Options(
          headers: const <String, Object?>{
            'Content-Type': _awsJsonContentType,
            'X-Amz-Target': _getCredentialsTarget,
          },
          responseType: ResponseType.plain,
          validateStatus: _isSuccessStatus,
        ),
      );
    } on DioException catch (error) {
      _debugPrintDioError('COGNITO Credentials ERROR', error);
      rethrow;
    }
    final data = _asMap(response.data);
    final credentials = data['Credentials'];
    if (credentials is! Map) {
      _debugPrint(
        'COGNITO Credentials ERROR missing Credentials '
        'status=${response.statusCode} keys=${_debugMapKeys(data)} '
        'awsError=${_debugAwsError(data)}',
      );
      throw const QuestionImageUploadException('Cognito 임시 자격 증명을 확인하지 못했습니다.');
    }

    final accessKeyId = credentials['AccessKeyId'];
    final secretKey = credentials['SecretKey'];
    final sessionToken = credentials['SessionToken'];
    if (accessKeyId is! String ||
        accessKeyId.trim().isEmpty ||
        secretKey is! String ||
        secretKey.trim().isEmpty ||
        sessionToken is! String ||
        sessionToken.trim().isEmpty) {
      _debugPrint(
        'COGNITO Credentials ERROR empty credential field '
        'status=${response.statusCode}',
      );
      throw const QuestionImageUploadException('Cognito 임시 자격 증명 값이 비어 있습니다.');
    }

    _debugPrint(
      'COGNITO Credentials RESPONSE status=${response.statusCode} '
      'accessKey=<redacted> secretKey=<redacted> sessionToken=<redacted>',
    );
    return _CognitoCredentials(
      accessKeyId: accessKeyId,
      secretKey: secretKey,
      sessionToken: sessionToken,
    );
  }

  Future<void> _putObject({
    required String objectKey,
    required Uint8List bytes,
    required String contentType,
    required _CognitoCredentials credentials,
    required DateTime now,
  }) async {
    final host = '${bucket.trim()}.s3.${region.trim()}.amazonaws.com';
    final canonicalUri = '/${_encodeKey(objectKey)}';
    final uri = Uri.parse('https://$host$canonicalUri');
    final payloadHash = sha256.convert(bytes).toString();
    final amzDate = _awsDateTime(now);
    final authorization = _authorizationHeader(
      method: 'PUT',
      canonicalUri: canonicalUri,
      host: host,
      contentType: contentType,
      payloadHash: payloadHash,
      amzDate: amzDate,
      now: now,
      credentials: credentials,
    );

    _debugPrint(
      'S3 PutObject REQUEST host=$host key=${_redactObjectKey(objectKey)} '
      'contentType=$contentType sizeBytes=${bytes.length} '
      'amzDate=$amzDate signedHeaders='
      'content-type;host;x-amz-content-sha256;x-amz-date;x-amz-security-token',
    );
    try {
      final response = await _dio.putUri<void>(
        uri,
        data: bytes,
        options: Options(
          headers: <String, Object?>{
            'authorization': authorization,
            'content-type': contentType,
            'x-amz-content-sha256': payloadHash,
            'x-amz-date': amzDate,
            'x-amz-security-token': credentials.sessionToken,
          },
          responseType: ResponseType.plain,
          validateStatus: _isSuccessStatus,
        ),
      );
      _debugPrint(
        'S3 PutObject RESPONSE status=${response.statusCode} '
        'key=${_redactObjectKey(objectKey)}',
      );
    } on DioException catch (error) {
      _debugPrintDioError('S3 PutObject ERROR', error);
      rethrow;
    }
  }

  String _authorizationHeader({
    required String method,
    required String canonicalUri,
    required String host,
    required String contentType,
    required String payloadHash,
    required String amzDate,
    required DateTime now,
    required _CognitoCredentials credentials,
  }) {
    final dateStamp = _dateStamp(now);
    final credentialScope = '$dateStamp/${region.trim()}/s3/aws4_request';
    final canonicalHeaders = <String, String>{
      'content-type': contentType,
      'host': host,
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
      'x-amz-security-token': credentials.sessionToken,
    };
    final signedHeaderNames = canonicalHeaders.keys.toList()..sort();
    final canonicalHeaderText = signedHeaderNames
        .map((name) => '$name:${_normalizeHeader(canonicalHeaders[name]!)}\n')
        .join();
    final signedHeaders = signedHeaderNames.join(';');
    final canonicalRequest = <String>[
      method,
      canonicalUri,
      '',
      canonicalHeaderText,
      signedHeaders,
      payloadHash,
    ].join('\n');
    final stringToSign = <String>[
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');
    final signingKey = _signingKey(
      secretKey: credentials.secretKey,
      dateStamp: dateStamp,
    );
    final signature = Hmac(
      sha256,
      signingKey,
    ).convert(utf8.encode(stringToSign)).toString();

    return 'AWS4-HMAC-SHA256 '
        'Credential=${credentials.accessKeyId}/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';
  }

  List<int> _signingKey({
    required String secretKey,
    required String dateStamp,
  }) {
    final dateKey = _hmac(utf8.encode('AWS4$secretKey'), dateStamp);
    final regionKey = _hmac(dateKey, region.trim());
    final serviceKey = _hmac(regionKey, 's3');
    return _hmac(serviceKey, 'aws4_request');
  }

  List<int> _hmac(List<int> key, String data) {
    return Hmac(sha256, key).convert(utf8.encode(data)).bytes;
  }

  String _buildObjectKey({
    required String identityId,
    required String fileName,
    required String contentType,
    required DateTime now,
  }) {
    final prefix = _trimSlashes(questionImagePrefix);
    final extension = _extensionFor(
      fileName: fileName,
      contentType: contentType,
    );
    final timestamp = _objectTimestamp(now);
    final name = 'question-$timestamp-${_nonce()}.$extension';
    return '$prefix/$identityId/$name';
  }

  String _extensionFor({
    required String fileName,
    required String contentType,
  }) {
    final byType = switch (contentType.trim().toLowerCase()) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => '',
    };
    if (byType.isNotEmpty) {
      return byType;
    }

    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < fileName.length - 1) {
      final extension = fileName.substring(dotIndex + 1).toLowerCase();
      if (extension == 'jpg' ||
          extension == 'jpeg' ||
          extension == 'png' ||
          extension == 'webp') {
        return extension == 'jpeg' ? 'jpg' : extension;
      }
    }
    throw const QuestionImageUploadException('지원하지 않는 이미지 형식입니다.');
  }

  Map<String, Object?> _asMap(Object? data) {
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        throw const QuestionImageUploadException('업로드 인증 응답이 비어 있습니다.');
      }
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return _mapFromDynamic(decoded);
      }
      throw const QuestionImageUploadException('업로드 인증 응답 형식을 확인하지 못했습니다.');
    }
    if (data is Map) {
      return _mapFromDynamic(data);
    }
    throw const QuestionImageUploadException('업로드 인증 응답을 확인하지 못했습니다.');
  }

  Map<String, Object?> _mapFromDynamic(Map<dynamic, dynamic> data) {
    return data.map<String, Object?>(
      (key, dynamic value) =>
          MapEntry<String, Object?>(key.toString(), value as Object?),
    );
  }

  void _validateConfig() {
    if (identityPoolId.trim().isEmpty ||
        bucket.trim().isEmpty ||
        region.trim().isEmpty ||
        publicBaseUrl.trim().isEmpty) {
      _debugPrint(
        'CONFIG ERROR identityPoolIdPresent=${identityPoolId.trim().isNotEmpty} '
        'bucketPresent=${bucket.trim().isNotEmpty} '
        'regionPresent=${region.trim().isNotEmpty} '
        'publicBaseUrlPresent=${publicBaseUrl.trim().isNotEmpty}',
      );
      throw const QuestionImageUploadException('S3 이미지 업로드 설정이 누락되었습니다.');
    }
  }

  void _validateUploadInput({
    required List<int> bytes,
    required String contentType,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (bytes.isEmpty) {
      throw const QuestionImageUploadException('이미지 파일을 읽지 못했습니다.');
    }
    if (contentType.trim().isEmpty) {
      throw const QuestionImageUploadException('이미지 형식을 확인하지 못했습니다.');
    }
    _ratioReader.fromDimensions(width: imageWidth, height: imageHeight);
  }

  Uri get _cognitoUri {
    return Uri.parse(
      'https://cognito-identity.${region.trim()}.amazonaws.com/',
    );
  }

  static bool _isSuccessStatus(int? status) {
    return status != null && status >= 200 && status < 300;
  }

  static String _normalizeHeader(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _encodeKey(String key) {
    return key.split('/').map(Uri.encodeComponent).join('/');
  }

  static String _trimSlashes(String value) {
    return value.trim().replaceAll(RegExp(r'^/+|/+$'), '');
  }

  static String _trimTrailingSlash(String value) {
    return value.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static String _awsDateTime(DateTime value) {
    final utc = value.toUtc();
    return '${_four(utc.year)}${_two(utc.month)}${_two(utc.day)}'
        'T${_two(utc.hour)}${_two(utc.minute)}${_two(utc.second)}Z';
  }

  static String _dateStamp(DateTime value) {
    final utc = value.toUtc();
    return '${_four(utc.year)}${_two(utc.month)}${_two(utc.day)}';
  }

  static String _objectTimestamp(DateTime value) {
    final utc = value.toUtc();
    return '${_four(utc.year)}${_two(utc.month)}${_two(utc.day)}'
        '${_two(utc.hour)}${_two(utc.minute)}${_two(utc.second)}';
  }

  static String _four(int value) => value.toString().padLeft(4, '0');

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _randomNonce() {
    final random = Random.secure();
    return List<int>.generate(
      8,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  void _debugPrint(String message) {
    if (!_debugLogsEnabled) {
      return;
    }
    debugPrint('[Taglow S3 Upload] $message');
  }

  void _debugPrintDioError(String phase, DioException error) {
    if (!_debugLogsEnabled) {
      return;
    }

    final response = error.response;
    if (response == null) {
      debugPrint(
        '[Taglow S3 Upload] $phase type=${error.type} '
        'message=${error.message}',
      );
      return;
    }

    debugPrint(
      '[Taglow S3 Upload] $phase status=${response.statusCode} '
      'type=${error.type} uri=${_debugUri(error.requestOptions.uri)}',
    );
  }

  String _debugUri(Uri uri) {
    if (uri.host == '${bucket.trim()}.s3.${region.trim()}.amazonaws.com') {
      return '${uri.scheme}://${uri.host}/${_redactObjectKeyFromPath(uri.path)}';
    }
    return '${uri.scheme}://${uri.host}${uri.path}';
  }

  String _debugMapKeys(Map<String, Object?> data) {
    if (data.isEmpty) {
      return '<empty>';
    }
    return data.keys.join(',');
  }

  String _debugAwsError(Map<String, Object?> data) {
    final output = data['Output'];
    if (output is Map) {
      final outputMap = _mapFromDynamic(output);
      return 'type=${outputMap['__type'] ?? '<none>'} '
          'message=${_truncateDebugValue((outputMap['message'] ?? '').toString())}';
    }
    return 'type=${data['__type'] ?? '<none>'} '
        'message=${_truncateDebugValue((data['message'] ?? '').toString())}';
  }

  String _debugFileName(String fileName) {
    final name = fileName.trim().split(RegExp(r'[/\\]')).last;
    if (name.isEmpty) {
      return '<empty>';
    }
    if (name.length <= 80) {
      return name;
    }
    return '${name.substring(0, 77)}...';
  }

  String _redactIdentityPoolId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '<empty>';
    }
    final colonIndex = trimmed.indexOf(':');
    if (colonIndex < 0) {
      return '<redacted>';
    }
    return '${trimmed.substring(0, colonIndex + 1)}<redacted>';
  }

  String _redactIdentityId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '<empty>';
    }
    final colonIndex = trimmed.indexOf(':');
    if (colonIndex < 0) {
      return '<redacted>';
    }
    return '${trimmed.substring(0, colonIndex + 1)}<redacted>';
  }

  String _redactObjectKey(String key) {
    final prefix = _trimSlashes(questionImagePrefix);
    final prefixWithSlash = '$prefix/';
    if (!key.startsWith(prefixWithSlash)) {
      return _truncateDebugValue(key);
    }

    final rest = key.substring(prefixWithSlash.length);
    final slashIndex = rest.indexOf('/');
    if (slashIndex < 0) {
      return '$prefix/<identity>';
    }
    return '$prefix/<identity>/${rest.substring(slashIndex + 1)}';
  }

  String _redactObjectKeyFromPath(String path) {
    final decodedPath = Uri.decodeComponent(
      path.replaceFirst(RegExp(r'^/+'), ''),
    );
    return _redactObjectKey(decodedPath);
  }

  String _truncateDebugValue(String value) {
    if (value.length <= 120) {
      return value;
    }
    return '${value.substring(0, 117)}...';
  }
}

class _CognitoCredentials {
  const _CognitoCredentials({
    required this.accessKeyId,
    required this.secretKey,
    required this.sessionToken,
  });

  final String accessKeyId;
  final String secretKey;
  final String sessionToken;
}
