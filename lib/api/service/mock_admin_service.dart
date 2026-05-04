import '../model/admin_question.dart';
import '../model/admin_user.dart';
import '../model/admin_vote.dart';
import '../model/vote_status.dart';
import 'admin_service.dart';

/// 외부 API 없이 관리자 흐름을 실행하는 in-memory [AdminService] 구현입니다.
/// Controller와 View 테스트가 real Service와 같은 계약으로 vote/question/auth 흐름을 검증하게 합니다.
/// 운영 링크와 upload Service는 별도 provider에서 mock/real을 교체합니다.
/// fields:
/// - [_currentUser]: 현재 mock 인증 사용자입니다.
/// - [_votes]: voteId를 key로 하는 mock vote 저장소입니다.
/// - [_questions]: voteId별 question 목록을 보관하는 mock 저장소입니다.
/// - [_nextVoteId]: 다음 mock vote 식별자를 만들기 위한 counter입니다.
/// - [_nextQuestionId]: 다음 mock question 식별자를 만들기 위한 counter입니다.
/// - [_nextUserId]: 다음 mock user 식별자를 만들기 위한 counter입니다.
class MockAdminService implements AdminService {
  /// mock service를 생성하고 기본 ADMIN 사용자와 sample vote/question을 준비합니다.
  /// 테스트는 [initialUser]로 권한 없는 사용자 같은 조건을 주입할 수 있습니다.
  /// Parameters:
  /// - [initialUser]: 초기 current user로 사용할 사용자입니다.
  /// Returns:
  /// - [instance]: in-memory 관리자 service 인스턴스입니다.
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

  /// 현재 mock 인증 사용자입니다.
  /// login, fetchCurrentUser, createVote의 createdByUserId에서 사용됩니다.
  AdminUser _currentUser;

  /// mock vote 저장소입니다.
  /// fetch/create/update/delete vote 동작이 이 map을 갱신합니다.
  final Map<String, AdminVote> _votes = {};

  /// voteId별 mock question 저장소입니다.
  /// vote 상세와 question CRUD가 이 map의 목록을 사용합니다.
  final Map<String, List<AdminQuestion>> _questions = {};

  /// 다음 vote id 생성을 위한 counter입니다.
  /// mock 생성 결과가 deterministic하게 증가하도록 유지됩니다.
  int _nextVoteId = 2;

  /// 다음 question id 생성을 위한 counter입니다.
  /// createQuestion이 새 question 식별자를 만들 때 사용합니다.
  int _nextQuestionId = 2;

  /// 다음 user id 생성을 위한 counter입니다.
  /// signup mock 응답의 사용자 식별자를 만들 때 사용합니다.
  int _nextUserId = 2;

  /// mock 회원가입을 수행하고 USER role 사용자를 반환합니다.
  /// 클라이언트가 ADMIN 승격을 하지 않는 PRD 정책을 테스트 환경에서도 유지합니다.
  /// Parameters:
  /// - [name]: 가입할 mock 사용자 이름입니다.
  /// - [password]: 가입 비밀번호이며 저장하지 않습니다.
  /// Returns:
  /// - [result]: USER role을 가진 새 [AdminUser]입니다.
  @override
  Future<AdminUser> signup({
    required String name,
    required String password,
  }) async {
    if (name.trim().isEmpty || password.trim().isEmpty) {
      throw StateError('Name and password are required.');
    }
    return AdminUser(
      id: (_nextUserId++).toString(),
      name: name.trim(),
      roles: const {'USER'},
    );
  }

  /// mock 로그인을 수행하고 ADMIN role current user를 반환합니다.
  /// 비어 있는 입력은 real API처럼 실패 흐름을 확인할 수 있게 오류를 던집니다.
  /// Parameters:
  /// - [name]: 로그인 사용자 이름입니다.
  /// - [password]: 로그인 비밀번호이며 저장하지 않습니다.
  /// Returns:
  /// - [result]: mock current user로 설정된 [AdminUser]입니다.
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

  /// 현재 mock 인증 사용자를 반환합니다.
  /// 앱 시작 session check 테스트에서 real Service와 같은 계약으로 호출됩니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 현재 mock 사용자입니다.
  @override
  Future<AdminUser?> fetchCurrentUser() async => _currentUser;

  /// mock 로그아웃을 수행합니다.
  /// 현재 구현은 상태를 유지하며 Controller의 로컬 상태 정리 동작을 검증할 수 있게 합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> logout() async {}

  /// mock vote 목록을 반환합니다.
  /// Controller는 real Service와 동일하게 [AdminVote] 목록을 받아 목록 상태를 구성합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 현재 mock vote 목록입니다.
  @override
  Future<List<AdminVote>> fetchVotes() async =>
      _votes.values.toList(growable: false);

  /// mock vote를 생성하고 저장소에 추가합니다.
  /// 생성자는 현재 mock user이며 question 목록도 빈 목록으로 초기화합니다.
  /// Parameters:
  /// - [name]: 생성할 vote 이름입니다.
  /// Returns:
  /// - [result]: 생성된 [AdminVote]입니다.
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

  /// mock vote 상세를 조회합니다.
  /// 없는 voteId는 Service 오류 흐름을 검증할 수 있도록 [StateError]를 던집니다.
  /// Parameters:
  /// - [voteId]: 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: 조회된 [AdminVote]입니다.
  @override
  Future<AdminVote> fetchVote(String voteId) async {
    final vote = _votes[voteId];
    if (vote == null) throw StateError('Vote not found: $voteId');
    return vote;
  }

  /// mock vote의 이름이나 상태를 수정합니다.
  /// 불변 [AdminVote.copyWith]를 사용해 updatedAt도 새 UTC 시각으로 갱신합니다.
  /// Parameters:
  /// - [voteId]: 수정할 vote 식별자입니다.
  /// - [name]: 새 vote 이름입니다.
  /// - [status]: 새 vote 상태입니다.
  /// Returns:
  /// - [result]: 수정된 [AdminVote]입니다.
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

  /// mock vote와 연결된 question 목록을 삭제합니다.
  /// 삭제 후 목록/상세 Controller가 empty state를 검증할 수 있습니다.
  /// Parameters:
  /// - [voteId]: 삭제할 vote 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> deleteVote(String voteId) async {
    _votes.remove(voteId);
    _questions.remove(voteId);
  }

  /// 특정 mock vote에 속한 question 목록을 반환합니다.
  /// 외부에서 저장소 목록을 직접 변경하지 못하도록 unmodifiable list를 반환합니다.
  /// Parameters:
  /// - [voteId]: question 목록을 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: 해당 vote의 [AdminQuestion] 목록입니다.
  @override
  Future<List<AdminQuestion>> fetchQuestions(String voteId) async {
    return List.unmodifiable(_questions[voteId] ?? const []);
  }

  /// mock question을 생성하고 vote별 목록에 추가합니다.
  /// real Service와 동일하게 imageUrl과 imageRatio를 받아 domain model을 생성합니다.
  /// Parameters:
  /// - [voteId]: question이 속할 vote 식별자입니다.
  /// - [title]: question 제목입니다.
  /// - [detail]: question 설명입니다.
  /// - [imageUrl]: 업로드된 공개 이미지 URL입니다.
  /// - [imageRatio]: 이미지 가로/세로 비율입니다.
  /// Returns:
  /// - [result]: 생성된 [AdminQuestion]입니다.
  @override
  Future<AdminQuestion> createQuestion({
    required String voteId,
    required String title,
    required String detail,
    required String imageUrl,
    required double imageRatio,
  }) async {
    if (!_votes.containsKey(voteId)) {
      throw StateError('Vote not found: $voteId');
    }
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

  /// mock question을 찾아 일부 값을 수정합니다.
  /// vote별 목록 전체를 순회해 questionId 기준으로 update 결과를 반영합니다.
  /// Parameters:
  /// - [questionId]: 수정할 question 식별자입니다.
  /// - [title]: 새 question 제목입니다.
  /// - [detail]: 새 question 설명입니다.
  /// - [imageUrl]: 새 공개 이미지 URL입니다.
  /// - [imageRatio]: 새 이미지 비율입니다.
  /// Returns:
  /// - [result]: 수정된 [AdminQuestion]입니다.
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

  /// 모든 mock vote 목록에서 question을 삭제합니다.
  /// 현재 mock 구조는 questionId만으로 삭제할 수 있도록 전체 목록을 검사합니다.
  /// Parameters:
  /// - [questionId]: 삭제할 question 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> deleteQuestion(String questionId) async {
    for (final questions in _questions.values) {
      questions.removeWhere((question) => question.id == questionId);
    }
  }

  /// mock public vote display payload를 반환합니다.
  /// 운영 미리보기와 player 데이터 확인 테스트가 real public API 없이 동작하게 합니다.
  /// Parameters:
  /// - [voteId]: 공개 display를 확인할 vote 식별자입니다.
  /// Returns:
  /// - [result]: public display 형태의 mock payload입니다.
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

  /// mock public question payload 목록을 반환합니다.
  /// player/participant 공개 API가 사용하는 중첩 question 형태를 테스트 fixture로 제공합니다.
  /// Parameters:
  /// - [voteId]: 공개 question 목록을 확인할 vote 식별자입니다.
  /// Returns:
  /// - [result]: public question payload 목록입니다.
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

  /// mock 데이터의 timestamp를 UTC 기준으로 생성합니다.
  /// 생성/수정 시각 표시 테스트가 timezone 변환을 View에서 다루게 합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 현재 UTC 시각입니다.
  DateTime _now() => DateTime.now().toUtc();
}
