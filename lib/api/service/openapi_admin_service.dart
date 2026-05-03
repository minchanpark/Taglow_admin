import '../model/admin_question.dart';
import '../model/admin_user.dart';
import '../model/admin_vote.dart';
import '../model/vote_status.dart';
import 'admin_api_gateway.dart';
import 'admin_payload_mapper.dart';
import 'admin_service.dart';

class OpenApiAdminService implements AdminService {
  OpenApiAdminService({
    required AdminApiGateway gateway,
    AdminPayloadMapper mapper = const AdminPayloadMapper(),
  }) : _gateway = gateway,
       _mapper = mapper;

  final AdminApiGateway _gateway;
  final AdminPayloadMapper _mapper;

  AdminUser? _currentUser;

  @override
  Future<AdminUser> signup({
    required String name,
    required String password,
  }) async {
    final payload = _mapper.signupToPayload(name: name, password: password);
    return _mapper.userFromPayload(await _gateway.signup(payload));
  }

  @override
  Future<AdminUser> login({
    required String name,
    required String password,
  }) async {
    final payload = _mapper.loginToPayload(name: name, password: password);
    final user = _mapper.userFromPayload(await _gateway.login(payload));
    _currentUser = user;
    return user;
  }

  @override
  Future<AdminUser?> fetchCurrentUser() async {
    final user = _mapper.userFromPayload(await _gateway.me());
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await _gateway.logout();
    _currentUser = null;
  }

  @override
  Future<List<AdminVote>> fetchVotes() async {
    return _mapper.votesFromPayloadList(await _gateway.fetchVotes());
  }

  @override
  Future<AdminVote> createVote({required String name}) async {
    final payload = _mapper.createVoteToPayload(
      name: name,
      createdByUserId: _currentUser?.id,
    );
    return _mapper.voteFromPayload(await _gateway.createVote(payload));
  }

  @override
  Future<AdminVote> fetchVote(String voteId) async {
    return _mapper.voteFromPayload(await _gateway.fetchVote(voteId));
  }

  @override
  Future<AdminVote> updateVote({
    required String voteId,
    String? name,
    VoteStatus? status,
  }) async {
    final payload = _mapper.updateVoteToPayload(name: name, status: status);
    return _mapper.voteFromPayload(
      await _gateway.updateVote(voteId: voteId, payload: payload),
    );
  }

  @override
  Future<void> deleteVote(String voteId) => _gateway.deleteVote(voteId);

  @override
  Future<List<AdminQuestion>> fetchQuestions(String voteId) async {
    return _mapper.questionsFromPayloadList(
      await _gateway.fetchQuestions(voteId),
    );
  }

  @override
  Future<AdminQuestion> createQuestion({
    required String voteId,
    required String title,
    required String detail,
    required String imageUrl,
    required double imageRatio,
  }) async {
    final payload = _mapper.createQuestionToPayload(
      voteId: voteId,
      title: title,
      detail: detail,
      imageUrl: imageUrl,
      imageRatio: imageRatio,
    );
    return _mapper.questionFromPayload(await _gateway.createQuestion(payload));
  }

  @override
  Future<AdminQuestion> updateQuestion({
    required String questionId,
    String? title,
    String? detail,
    String? imageUrl,
    double? imageRatio,
  }) async {
    final payload = _mapper.updateQuestionToPayload(
      title: title,
      detail: detail,
      imageUrl: imageUrl,
      imageRatio: imageRatio,
    );
    return _mapper.questionFromPayload(
      await _gateway.updateQuestion(questionId: questionId, payload: payload),
    );
  }

  @override
  Future<void> deleteQuestion(String questionId) {
    return _gateway.deleteQuestion(questionId);
  }

  @override
  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId) {
    return _gateway.fetchPublicVoteDisplay(voteId);
  }

  @override
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId) {
    return _gateway.fetchPublicQuestions(voteId);
  }
}
