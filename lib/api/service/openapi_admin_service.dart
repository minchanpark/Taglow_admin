import '../model/admin_question.dart';
import '../model/admin_user.dart';
import '../model/admin_vote.dart';
import '../model/vote_status.dart';
import 'admin_api_gateway.dart';
import 'admin_payload_mapper.dart';
import 'admin_service.dart';

/// Gateway와 Mapper를 조합하는 real 관리자 [AdminService] 구현입니다.
/// Controller에는 domain model만 반환하고 raw payload, endpoint, generated client 변화는 하위 계층에 격리합니다.
/// 로그인한 사용자 id는 vote 생성 payload 보강에만 사용합니다.
/// fields:
/// - [_gateway]: API 호출과 raw payload 정규화를 담당하는 Gateway입니다.
/// - [_mapper]: raw payload와 domain model 사이 변환을 담당하는 Mapper입니다.
/// - [_currentUser]: 현재 인증된 사용자이며 vote 생성자 값에 사용됩니다.
class OpenApiAdminService implements AdminService {
  /// real 관리자 service를 생성합니다.
  /// provider가 환경별 Gateway와 Mapper를 주입해 Controller dependency를 안정화합니다.
  /// Parameters:
  /// - [gateway]: low-level API 호출을 수행하는 Gateway입니다.
  /// - [mapper]: payload와 domain model을 변환하는 Mapper입니다.
  /// Returns:
  /// - [instance]: OpenAPI/Gateway 기반 관리자 service 인스턴스입니다.
  OpenApiAdminService({
    required AdminApiGateway gateway,
    AdminPayloadMapper mapper = const AdminPayloadMapper(),
  }) : _gateway = gateway,
       _mapper = mapper;

  /// endpoint, credential, raw payload 처리를 담당하는 Gateway입니다.
  /// Service는 Gateway 결과를 직접 View에 넘기지 않고 Mapper로 변환합니다.
  final AdminApiGateway _gateway;

  /// payload와 domain model 변환을 담당하는 Mapper입니다.
  /// 서버 DTO 변화는 이 의존성에서 우선 흡수합니다.
  final AdminPayloadMapper _mapper;

  /// 현재 인증된 사용자입니다.
  /// vote 생성 시 createdByUserId를 보강할 수 있도록 service 내부에만 유지합니다.
  AdminUser? _currentUser;

  /// 회원가입 payload를 만들고 Gateway 응답을 [AdminUser]로 변환합니다.
  /// ADMIN role 승격 payload는 포함하지 않습니다.
  /// Parameters:
  /// - [name]: 가입할 사용자 이름 또는 아이디입니다.
  /// - [password]: 가입 비밀번호입니다.
  /// Returns:
  /// - [result]: 생성된 [AdminUser]입니다.
  @override
  Future<AdminUser> signup({
    required String name,
    required String password,
  }) async {
    final payload = _mapper.signupToPayload(name: name, password: password);
    return _mapper.userFromPayload(await _gateway.signup(payload));
  }

  /// 로그인 payload를 만들고 인증 사용자 domain model을 반환합니다.
  /// 성공한 사용자는 vote 생성 흐름에서 참조할 수 있도록 [_currentUser]에 보관합니다.
  /// Parameters:
  /// - [name]: 로그인 사용자 이름 또는 아이디입니다.
  /// - [password]: 로그인 비밀번호입니다.
  /// Returns:
  /// - [result]: 인증된 [AdminUser]입니다.
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

  /// 현재 세션 사용자를 Gateway에서 조회하고 domain model로 변환합니다.
  /// 결과는 service 내부 current user에도 동기화됩니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 현재 인증된 [AdminUser]입니다.
  @override
  Future<AdminUser?> fetchCurrentUser() async {
    final payload = await _gateway.me();
    if (payload == null) {
      _currentUser = null;
      return null;
    }
    final user = _mapper.userFromPayload(payload);
    _currentUser = user;
    return user;
  }

  /// 서버 logout을 호출하고 service 내부 사용자 상태를 비웁니다.
  /// Controller는 완료 후 로컬 auth state를 별도로 정리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> logout() async {
    await _gateway.logout();
    _currentUser = null;
  }

  /// Gateway vote 목록 payload를 조회해 domain model 목록으로 변환합니다.
  /// Controller는 generated DTO나 raw JSON 구조를 알지 않습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 관리자 vote 목록입니다.
  @override
  Future<List<AdminVote>> fetchVotes() async {
    return _mapper.votesFromPayloadList(await _gateway.fetchVotes());
  }

  /// 새 vote 생성 payload를 만들고 생성 결과를 domain model로 변환합니다.
  /// 현재 사용자 id가 있으면 Mapper를 통해 생성자 값으로 포함합니다.
  /// Parameters:
  /// - [name]: 생성할 vote 이름입니다.
  /// Returns:
  /// - [result]: 생성된 [AdminVote]입니다.
  @override
  Future<AdminVote> createVote({required String name}) async {
    final payload = _mapper.createVoteToPayload(
      name: name,
      createdByUserId: _currentUser?.id,
    );
    return _mapper.voteFromPayload(await _gateway.createVote(payload));
  }

  /// 단일 vote payload를 조회해 [AdminVote]로 변환합니다.
  /// route parameter encoding은 Gateway가 담당합니다.
  /// Parameters:
  /// - [voteId]: 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: 조회된 [AdminVote]입니다.
  @override
  Future<AdminVote> fetchVote(String voteId) async {
    return _mapper.voteFromPayload(await _gateway.fetchVote(voteId));
  }

  /// vote update payload를 만들고 수정 결과를 domain model로 변환합니다.
  /// 상태 enum은 Mapper에서 서버 문자열로 바뀝니다.
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
    final payload = _mapper.updateVoteToPayload(name: name, status: status);
    return _mapper.voteFromPayload(
      await _gateway.updateVote(voteId: voteId, payload: payload),
    );
  }

  /// vote 삭제를 Gateway에 위임합니다.
  /// Service는 domain model 변환이 필요 없는 완료 동작만 반환합니다.
  /// Parameters:
  /// - [voteId]: 삭제할 vote 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> deleteVote(String voteId) => _gateway.deleteVote(voteId);

  /// question 목록 payload를 조회해 [AdminQuestion] 목록으로 변환합니다.
  /// Vote detail Controller와 목록 count 계산이 같은 계약을 사용합니다.
  /// Parameters:
  /// - [voteId]: question 목록을 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: 해당 vote의 question 목록입니다.
  @override
  Future<List<AdminQuestion>> fetchQuestions(String voteId) async {
    return _mapper.questionsFromPayloadList(
      await _gateway.fetchQuestions(voteId),
    );
  }

  /// question 생성 payload를 만들고 생성 결과를 domain model로 변환합니다.
  /// 이미지 bytes 없이 imageUrl과 imageRatio만 서버에 전달합니다.
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
    final payload = _mapper.createQuestionToPayload(
      voteId: voteId,
      title: title,
      detail: detail,
      imageUrl: imageUrl,
      imageRatio: imageRatio,
    );
    return _mapper.questionFromPayload(await _gateway.createQuestion(payload));
  }

  /// question update payload를 만들고 수정 결과를 domain model로 변환합니다.
  /// null이 아닌 field만 Mapper를 통해 Gateway로 전달합니다.
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

  /// question 삭제를 Gateway에 위임합니다.
  /// 삭제 결과는 domain model 없이 완료 상태만 Controller에 전달됩니다.
  /// Parameters:
  /// - [questionId]: 삭제할 question 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  @override
  Future<void> deleteQuestion(String questionId) {
    return _gateway.deleteQuestion(questionId);
  }

  /// public vote display payload 조회를 Gateway에 위임합니다.
  /// 운영 미리보기용 raw map은 Service 계약에 맞춰 정규화된 payload로 유지됩니다.
  /// Parameters:
  /// - [voteId]: 공개 display를 확인할 vote 식별자입니다.
  /// Returns:
  /// - [result]: public vote display payload입니다.
  @override
  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId) {
    return _gateway.fetchPublicVoteDisplay(voteId);
  }

  /// public question payload 목록 조회를 Gateway에 위임합니다.
  /// player/participant 데이터 확인 흐름에서 raw DTO 대신 map 목록을 반환합니다.
  /// Parameters:
  /// - [voteId]: 공개 question 목록을 확인할 vote 식별자입니다.
  /// Returns:
  /// - [result]: public question payload 목록입니다.
  @override
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId) {
    return _gateway.fetchPublicQuestions(voteId);
  }
}
