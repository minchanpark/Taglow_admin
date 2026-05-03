import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taglow_admin/api/service/admin_api_gateway.dart';

void main() {
  test('uses Dio endpoints and normalizes admin payloads', () async {
    final adapter = _AdminApiAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.taglow.test'));
    dio.httpClientAdapter = adapter;
    final gateway = DioAdminApiGateway(dio: dio);

    final user = await gateway.login(<String, Object?>{
      'name': 'admin',
      'password': 'password',
    });
    final votes = await gateway.fetchVotes();
    final createdVote = await gateway.createVote(<String, Object?>{
      'name': '운영 테스트',
      'createdByUserId': 1,
    });
    final createdQuestion = await gateway.createQuestion(<String, Object?>{
      'voteId': 1,
      'title': '첫 질문',
      'detail': '이미지 위에 태그를 남겨주세요.',
      'imageUrl': 'https://cdn.taglow.test/question.png',
      'imageRatio': 1.5,
    });
    final display = await gateway.fetchPublicVoteDisplay('1');
    final publicQuestions = await gateway.fetchPublicQuestions('1');

    expect(adapter.paths, <String>[
      '/api/auth/login',
      '/api/votes',
      '/api/public/votes',
      '/api/questions',
      '/api/public/votes/1/display',
      '/api/public/votes/1/questions',
    ]);
    expect(user['userId'], 1);
    expect(votes.single['id'], 1);
    expect(createdVote['name'], '운영 테스트');
    expect(createdQuestion['imageRatio'], 1.5);
    expect(display['voteName'], '운영 테스트');
    expect(publicQuestions.single['id'], 11);
    expect(adapter.bodies[0]['password'], 'password');
    expect(adapter.bodies[1]['createdByUserId'], 1);
    expect(adapter.bodies[2]['imageRatio'], 1.5);
  });

  test('adds JSON content type only when a request has a body', () async {
    final adapter = _AdminApiAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.taglow.test'));
    dio.httpClientAdapter = adapter;
    final gateway = DioAdminApiGateway(dio: dio);

    await gateway.fetchVotes();
    await gateway.createVote(<String, Object?>{'name': '새 투표'});

    expect(adapter.headers[0].containsKey(Headers.contentTypeHeader), isFalse);
    expect(
      adapter.headers[1][Headers.contentTypeHeader],
      Headers.jsonContentType,
    );
  });
}

class _AdminApiAdapter implements HttpClientAdapter {
  final List<String> paths = <String>[];
  final List<String> methods = <String>[];
  final List<Map<String, Object?>> headers = <Map<String, Object?>>[];
  final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    methods.add(options.method);
    headers.add(options.headers.cast<String, Object?>());
    final requestBody = await _readRequestBody(requestStream);
    if (requestBody != null) {
      bodies.add(requestBody);
    }

    final body = switch ((options.method, options.path)) {
      ('POST', '/api/auth/login') => <String, Object?>{
        'userId': 1,
        'name': 'admin',
        'roles': <String>['ADMIN'],
      },
      ('GET', '/api/votes') => <Object?>[
        <String, Object?>{
          'id': 1,
          'name': '운영 테스트',
          'status': 'PROGRESS',
          'createdByUserId': 1,
          'isMine': true,
        },
      ],
      ('POST', '/api/public/votes') => <String, Object?>{
        'id': 2,
        'status': 'PROGRESS',
        ...bodies.last,
      },
      ('POST', '/api/questions') => <String, Object?>{'id': 11, ...bodies.last},
      ('GET', '/api/public/votes/1/display') => <String, Object?>{
        'voteId': 1,
        'voteName': '운영 테스트',
        'status': 'PROGRESS',
        'questions': <Object?>[],
      },
      ('GET', '/api/public/votes/1/questions') => <Object?>[
        <String, Object?>{
          'id': 11,
          'voteId': 1,
          'title': '첫 질문',
          'detail': '이미지 위에 태그를 남겨주세요.',
          'imageUrl': 'https://cdn.taglow.test/question.png',
          'imageRatio': 1.5,
        },
      ],
      _ => throw StateError(
        'Unexpected request: ${options.method} ${options.path}',
      ),
    };

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  Future<Map<String, Object?>?> _readRequestBody(
    Stream<Uint8List>? requestStream,
  ) async {
    if (requestStream == null) {
      return null;
    }
    final bytes = <int>[];
    await for (final chunk in requestStream) {
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map) {
      return decoded.map<String, Object?>(
        (key, dynamic value) =>
            MapEntry<String, Object?>(key.toString(), value as Object?),
      );
    }
    return null;
  }
}
