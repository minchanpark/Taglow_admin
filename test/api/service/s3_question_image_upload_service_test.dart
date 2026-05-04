import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taglow_admin/api/service/question_image_upload_service.dart';
import 'package:taglow_admin/api/service/s3_question_image_upload_service.dart';
import 'package:taglow_admin/utils/env_config.dart';

void main() {
  test('EnvConfig provides the default non-secret S3 upload settings', () {
    const env = EnvConfig();

    expect(env.hasS3UploadConfig, isTrue);
    expect(env.missingS3UploadConfigKeys, isEmpty);
    expect(env.cognitoIdentityPoolId, startsWith('ap-northeast-2:'));
    expect(env.s3Bucket, 'tagvote-content-bucket');
    expect(
      env.s3PublicBaseUrl,
      'https://tagvote-content-bucket.s3.ap-northeast-2.amazonaws.com',
    );
  });

  test('EnvConfig reports exactly which S3 upload settings are missing', () {
    const env = EnvConfig(
      cognitoIdentityPoolId: '',
      s3Bucket: '',
      s3Region: '',
      s3PublicBaseUrl: '',
      s3QuestionImagePrefix: '',
    );

    expect(env.hasS3UploadConfig, isFalse);
    expect(env.missingS3UploadConfigKeys, <String>[
      'TAGLOW_COGNITO_IDENTITY_POOL_ID',
      'TAGLOW_S3_BUCKET',
      'TAGLOW_AWS_REGION',
      'TAGLOW_S3_PUBLIC_BASE_URL',
      'TAGLOW_S3_QUESTION_IMAGE_PREFIX',
    ]);
  });

  test('uploads a question image to S3 with Cognito credentials', () async {
    final adapter = _S3UploadAdapter();
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    final service = S3QuestionImageUploadService(
      identityPoolId: 'ap-northeast-2:pool',
      bucket: 'tagvote-content-bucket',
      region: 'ap-northeast-2',
      publicBaseUrl: 'https://cdn.taglow.test',
      dio: dio,
      now: () => DateTime.utc(2026, 5, 4, 1, 2, 3),
      nonce: () => 'fixednonce',
      debugLogsEnabled: false,
    );

    final result = await service.uploadQuestionImage(
      bytes: <int>[1, 2, 3],
      fileName: 'poster.png',
      contentType: 'image/png',
      imageWidth: 900,
      imageHeight: 600,
    );

    expect(adapter.targets, <String>[
      'com.amazonaws.cognito.identity.model.AWSCognitoIdentityService.GetId',
      'com.amazonaws.cognito.identity.model.'
          'AWSCognitoIdentityService.GetCredentialsForIdentity',
    ]);
    expect(adapter.cognitoContentTypes, <String>[
      'application/x-amz-json-1.1',
      'application/x-amz-json-1.1',
    ]);
    expect(
      result.objectKey,
      'public/question-images/ap-northeast-2:identity/'
      'question-20260504010203-fixednonce.png',
    );
    expect(
      result.publicUrl,
      'https://cdn.taglow.test/public/question-images/'
      'ap-northeast-2%3Aidentity/question-20260504010203-fixednonce.png',
    );
    expect(result.imageRatio, 1.5);
    expect(adapter.s3Bytes, <int>[1, 2, 3]);
    expect(
      adapter.s3Path,
      '/public/question-images/ap-northeast-2%3Aidentity/'
      'question-20260504010203-fixednonce.png',
    );
    expect(
      adapter.s3Headers['authorization'],
      startsWith(
        'AWS4-HMAC-SHA256 Credential=AKIA_TEST/20260504/'
        'ap-northeast-2/s3/aws4_request',
      ),
    );
    expect(adapter.s3Headers['x-amz-date'], '20260504T010203Z');
    expect(adapter.s3Headers['x-amz-security-token'], 'SESSION_TOKEN');
  });

  test('maps S3 upload failures to a safe message', () async {
    final adapter = _S3UploadAdapter(failS3Put: true);
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    final service = S3QuestionImageUploadService(
      identityPoolId: 'ap-northeast-2:pool',
      bucket: 'tagvote-content-bucket',
      region: 'ap-northeast-2',
      publicBaseUrl: 'https://cdn.taglow.test',
      dio: dio,
      now: () => DateTime.utc(2026, 5, 4, 1, 2, 3),
      nonce: () => 'fixednonce',
      debugLogsEnabled: false,
    );

    expect(
      () => service.uploadQuestionImage(
        bytes: <int>[1, 2, 3],
        fileName: 'poster.png',
        contentType: 'image/png',
        imageWidth: 900,
        imageHeight: 600,
      ),
      throwsA(
        isA<QuestionImageUploadException>().having(
          (error) => error.message,
          'message',
          '이미지 업로드에 실패했습니다. S3/Cognito CORS와 권한 설정을 확인해주세요.',
        ),
      ),
    );
  });
}

class _S3UploadAdapter implements HttpClientAdapter {
  _S3UploadAdapter({this.failS3Put = false});

  final bool failS3Put;
  final List<String> targets = <String>[];
  final List<String> cognitoContentTypes = <String>[];
  Map<String, Object?> s3Headers = <String, Object?>{};
  List<int> s3Bytes = <int>[];
  String? s3Path;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = await _readRequestBytes(requestStream);
    if (options.uri.host.startsWith('cognito-identity.')) {
      final target = _header(options, 'X-Amz-Target');
      targets.add(target);
      cognitoContentTypes.add(_header(options, Headers.contentTypeHeader));
      final body = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final response = switch (target) {
        'com.amazonaws.cognito.identity.model.AWSCognitoIdentityService.GetId' =>
          <String, Object?>{'IdentityId': 'ap-northeast-2:identity'},
        'com.amazonaws.cognito.identity.model.'
                'AWSCognitoIdentityService.GetCredentialsForIdentity'
            when body['IdentityId'] == 'ap-northeast-2:identity' =>
          <String, Object?>{
            'IdentityId': 'ap-northeast-2:identity',
            'Credentials': <String, Object?>{
              'AccessKeyId': 'AKIA_TEST',
              'SecretKey': 'SECRET_TEST',
              'SessionToken': 'SESSION_TOKEN',
            },
          },
        _ => throw StateError('Unexpected Cognito request: $target'),
      };
      return _json(response);
    }

    if (options.uri.host ==
        'tagvote-content-bucket.s3.ap-northeast-2.amazonaws.com') {
      s3Headers = options.headers.cast<String, Object?>();
      s3Bytes = bytes;
      s3Path = options.uri.path;
      return ResponseBody.fromString(
        '',
        failS3Put ? 403 : 200,
        headers: <String, List<String>>{},
      );
    }

    throw StateError('Unexpected request host: ${options.uri.host}');
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _json(Map<String, Object?> data) {
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  String _header(RequestOptions options, String name) {
    for (final entry in options.headers.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) {
        return entry.value.toString();
      }
    }
    return '';
  }

  Future<List<int>> _readRequestBytes(Stream<Uint8List>? requestStream) async {
    if (requestStream == null) {
      return <int>[];
    }
    final bytes = <int>[];
    await for (final chunk in requestStream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }
}
