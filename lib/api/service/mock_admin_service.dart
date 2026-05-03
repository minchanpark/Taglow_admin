import '../model/admin_question.dart';
import '../model/admin_user.dart';
import '../model/admin_vote.dart';
import '../model/vote_status.dart';
import 'admin_service.dart';

class MockAdminService implements AdminService {
  MockAdminService({AdminUser? initialUser})
    : _currentUser =
          initialUser ??
          const AdminUser(id: '1', name: 'admin', roles: {'ADMIN'}) {
    _votes['1'] = AdminVote(
      id: '1',
      name: 'Mock vote',
      status: VoteStatus.progress,
      createdByUserId: _currentUser.id,
      isMine: true,
      createdAt: _now(),
      updatedAt: _now(),
    );
    _questions['1'] = [
      AdminQuestion(
        id: '1',
        voteId: '1',
        title: 'Mock question',
        detail: 'Mock question detail',
        imageUrl: 'https://example.com/mock-question.jpg',
        imageRatio: 1,
        createdAt: _now(),
        updatedAt: _now(),
      ),
    ];
  }

  AdminUser _currentUser;
  final Map<String, AdminVote> _votes = {};
  final Map<String, List<AdminQuestion>> _questions = {};
  int _nextVoteId = 2;
  int _nextQuestionId = 2;

  @override
  Future<AdminUser> login({
    required String name,
    required String password,
  }) async {
    if (name.trim().isEmpty || password.trim().isEmpty) {
      throw StateError('Name and password are required.');
    }
    _currentUser = AdminUser(
      id: _currentUser.id,
      name: name,
      roles: const {'ADMIN'},
    );
    return _currentUser;
  }

  @override
  Future<AdminUser?> fetchCurrentUser() async => _currentUser;

  @override
  Future<void> logout() async {}

  @override
  Future<List<AdminVote>> fetchVotes() async =>
      _votes.values.toList(growable: false);

  @override
  Future<AdminVote> createVote({required String name}) async {
    final id = (_nextVoteId++).toString();
    final vote = AdminVote(
      id: id,
      name: name,
      status: VoteStatus.progress,
      createdByUserId: _currentUser.id,
      isMine: true,
      createdAt: _now(),
      updatedAt: _now(),
    );
    _votes[id] = vote;
    _questions[id] = [];
    return vote;
  }

  @override
  Future<AdminVote> fetchVote(String voteId) async {
    final vote = _votes[voteId];
    if (vote == null) throw StateError('Vote not found: $voteId');
    return vote;
  }

  @override
  Future<AdminVote> updateVote({
    required String voteId,
    String? name,
    VoteStatus? status,
  }) async {
    final vote = await fetchVote(voteId);
    final updated = vote.copyWith(
      name: name,
      status: status,
      updatedAt: _now(),
    );
    _votes[voteId] = updated;
    return updated;
  }

  @override
  Future<void> deleteVote(String voteId) async {
    _votes.remove(voteId);
    _questions.remove(voteId);
  }

  @override
  Future<List<AdminQuestion>> fetchQuestions(String voteId) async {
    return List.unmodifiable(_questions[voteId] ?? const []);
  }

  @override
  Future<AdminQuestion> createQuestion({
    required String voteId,
    required String title,
    required String detail,
    required String imageUrl,
    required double imageRatio,
  }) async {
    if (!_votes.containsKey(voteId))
      throw StateError('Vote not found: $voteId');
    final question = AdminQuestion(
      id: (_nextQuestionId++).toString(),
      voteId: voteId,
      title: title,
      detail: detail,
      imageUrl: imageUrl,
      imageRatio: imageRatio,
      createdAt: _now(),
      updatedAt: _now(),
    );
    _questions.putIfAbsent(voteId, () => []).add(question);
    return question;
  }

  @override
  Future<AdminQuestion> updateQuestion({
    required String questionId,
    String? title,
    String? detail,
    String? imageUrl,
    double? imageRatio,
  }) async {
    for (final entry in _questions.entries) {
      final index = entry.value.indexWhere(
        (question) => question.id == questionId,
      );
      if (index >= 0) {
        final updated = entry.value[index].copyWith(
          title: title,
          detail: detail,
          imageUrl: imageUrl,
          imageRatio: imageRatio,
          updatedAt: _now(),
        );
        entry.value[index] = updated;
        return updated;
      }
    }
    throw StateError('Question not found: $questionId');
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    for (final questions in _questions.values) {
      questions.removeWhere((question) => question.id == questionId);
    }
  }

  @override
  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId) async {
    final vote = await fetchVote(voteId);
    return {
      'voteId': int.tryParse(vote.id) ?? vote.id,
      'voteName': vote.name,
      'status': vote.status.serverValue,
      'questions': await fetchPublicQuestions(voteId),
    };
  }

  @override
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId) async {
    final questions = await fetchQuestions(voteId);
    return questions
        .map(
          (question) => {
            'question': {
              'id': int.tryParse(question.id) ?? question.id,
              'voteId': int.tryParse(question.voteId) ?? question.voteId,
              'title': question.title,
              'detail': question.detail,
              'imageUrl': question.imageUrl,
              'imageRatio': question.imageRatio,
              'createdAt': question.createdAt?.toIso8601String(),
              'updatedAt': question.updatedAt?.toIso8601String(),
            },
            'tags': <Map<String, Object?>>[],
          },
        )
        .toList(growable: false);
  }

  DateTime _now() => DateTime.now().toUtc();
}
