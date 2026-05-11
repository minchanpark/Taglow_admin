import 'package:flutter_test/flutter_test.dart';
import 'package:taglow_admin/api/service/admin_payload_mapper.dart';

void main() {
  const mapper = AdminPayloadMapper();

  test('encodes question imageRatio as a temporary scaled integer', () {
    final createPayload = mapper.createQuestionToPayload(
      voteId: '1',
      title: '지도 항목',
      detail: '세로형 이미지',
      imageUrl: 'https://cdn.taglow.test/question.png',
      imageRatio: 0.5625,
    );
    final updatePayload = mapper.updateQuestionToPayload(imageRatio: 1.7778);

    expect(createPayload['imageRatio'], 5625);
    expect(updatePayload['imageRatio'], 17778);
  });

  test('decodes temporary scaled integer imageRatio back to domain double', () {
    final encodedQuestion = mapper.questionFromPayload(<String, Object?>{
      'id': 11,
      'voteId': 1,
      'title': '지도 항목',
      'detail': '세로형 이미지',
      'imageUrl': 'https://cdn.taglow.test/question.png',
      'imageRatio': 5625,
    });
    final futureDoubleQuestion = mapper.questionFromPayload(<String, Object?>{
      'id': 12,
      'voteId': 1,
      'title': '가로형 이미지',
      'detail': '',
      'imageUrl': 'https://cdn.taglow.test/wide.png',
      'imageRatio': 1.5,
    });
    final legacyIntegerQuestion = mapper.questionFromPayload(<String, Object?>{
      'id': 13,
      'voteId': 1,
      'title': '기존 정수 이미지',
      'detail': '',
      'imageUrl': 'https://cdn.taglow.test/legacy.png',
      'imageRatio': 1,
    });

    expect(encodedQuestion.imageRatio, 0.5625);
    expect(futureDoubleQuestion.imageRatio, 1.5);
    expect(legacyIntegerQuestion.imageRatio, 1);
  });
}
