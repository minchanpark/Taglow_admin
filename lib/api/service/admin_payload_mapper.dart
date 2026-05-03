import '../model/admin_question.dart';
import '../model/admin_user.dart';
import '../model/admin_vote.dart';
import '../model/vote_status.dart';

class AdminPayloadMapper {
  const AdminPayloadMapper();

  Map<String, Object?> loginToPayload({
    required String name,
    required String password,
  }) {
    return {'name': name, 'password': password};
  }

  Map<String, Object?> signupToPayload({
    required String name,
    required String password,
  }) {
    return {'name': name, 'password': password};
  }

  AdminUser userFromPayload(Map<String, Object?> payload) {
    return AdminUser(
      id: _string(payload['id'] ?? payload['userId']),
      name: _string(payload['name']),
      roles: _stringSet(payload['roles']),
    );
  }

  Map<String, Object?> createVoteToPayload({
    required String name,
    String? createdByUserId,
  }) {
    return _withoutNulls({
      'name': name,
      if (createdByUserId != null)
        'createdByUserId': _intOrString(createdByUserId),
    });
  }

  Map<String, Object?> updateVoteToPayload({String? name, VoteStatus? status}) {
    return _withoutNulls({'name': name, 'status': status?.serverValue});
  }

  AdminVote voteFromPayload(Map<String, Object?> payload) {
    return AdminVote(
      id: _string(payload['id'] ?? payload['voteId']),
      name: _string(payload['name'] ?? payload['voteName']),
      status: VoteStatus.fromServerValue(payload['status']),
      createdByUserId: _string(payload['createdByUserId']),
      isMine: payload['isMine'] == true,
      createdAt: _date(payload['createdAt']),
      updatedAt: _date(payload['updatedAt']),
    );
  }

  List<AdminVote> votesFromPayloadList(List<Map<String, Object?>> payloads) {
    return payloads.map(voteFromPayload).toList(growable: false);
  }

  Map<String, Object?> createQuestionToPayload({
    required String voteId,
    required String title,
    required String detail,
    required String imageUrl,
    required double imageRatio,
  }) {
    return {
      'voteId': _intOrString(voteId),
      'title': title,
      'detail': detail,
      'imageUrl': imageUrl,
      'imageRatio': imageRatio,
    };
  }

  Map<String, Object?> updateQuestionToPayload({
    String? title,
    String? detail,
    String? imageUrl,
    double? imageRatio,
  }) {
    return _withoutNulls({
      'title': title,
      'detail': detail,
      'imageUrl': imageUrl,
      'imageRatio': imageRatio,
    });
  }

  AdminQuestion questionFromPayload(Map<String, Object?> payload) {
    final questionPayload = payload['question'];
    final normalized = questionPayload is Map
        ? questionPayload.map(
            (key, dynamic value) => MapEntry(key.toString(), value),
          )
        : payload;

    return AdminQuestion(
      id: _string(normalized['id'] ?? normalized['questionId']),
      voteId: _string(normalized['voteId']),
      title: _string(normalized['title']),
      detail: _string(normalized['detail'] ?? normalized['description']),
      imageUrl: _string(normalized['imageUrl']),
      imageRatio: _double(normalized['imageRatio'], fallback: 1),
      createdAt: _date(normalized['createdAt']),
      updatedAt: _date(normalized['updatedAt']),
    );
  }

  List<AdminQuestion> questionsFromPayloadList(
    List<Map<String, Object?>> payloads,
  ) {
    return payloads.map(questionFromPayload).toList(growable: false);
  }

  String _string(Object? value) => value?.toString() ?? '';

  Set<String> _stringSet(Object? value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toSet();
    }
    return const <String>{};
  }

  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  double _double(Object? value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Object _intOrString(String value) {
    return int.tryParse(value) ?? value;
  }

  Map<String, Object?> _withoutNulls(Map<String, Object?> value) {
    return Map.fromEntries(value.entries.where((entry) => entry.value != null));
  }
}
