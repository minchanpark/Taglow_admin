import '../model/admin_question.dart';
import '../model/admin_user.dart';
import '../model/admin_vote.dart';
import '../model/vote_status.dart';

/// Controller가 사용하는 관리자 기능의 service 계약입니다.
/// Mock/OpenAPI 구현은 이 인터페이스를 공유해 View와 Controller가 환경 차이를 알지 않게 합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
abstract class AdminService {
  /// 신규 사용자 생성을 요청합니다.
  /// 서버 정책상 ADMIN 승격은 수행하지 않고 auth 흐름은 Controller가 후속 처리합니다.
  /// Parameters:
  /// - [name]: 가입할 사용자 이름 또는 아이디입니다.
  /// - [password]: 가입 비밀번호이며 Service 밖 상태에 저장하지 않습니다.
  /// Returns:
  /// - [result]: 서버나 mock 구현이 생성한 [AdminUser]입니다.
  Future<AdminUser> signup({required String name, required String password});

  /// 사용자 인증을 요청하고 인증된 사용자를 반환합니다.
  /// 콘솔 접근 role 확인은 [AuthController]가 domain model 기준으로 수행합니다.
  /// Parameters:
  /// - [name]: 로그인 사용자 이름 또는 아이디입니다.
  /// - [password]: 로그인 비밀번호이며 Service 밖 상태에 저장하지 않습니다.
  /// Returns:
  /// - [result]: 인증된 [AdminUser]입니다.
  Future<AdminUser> login({required String name, required String password});

  /// 현재 세션의 사용자를 조회합니다.
  /// Gateway 인증 방식이 cookie/token 중 무엇이든 Controller에는 domain model로 전달됩니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 현재 사용자이거나 인증되지 않은 경우 null입니다.
  Future<AdminUser?> fetchCurrentUser();

  /// 현재 인증 세션을 종료합니다.
  /// 구현체는 서버 logout이나 mock 상태 정리를 수행합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> logout();

  /// 관리자 vote 목록을 조회합니다.
  /// 구현체는 payload/DTO 차이를 domain model 목록으로 정규화해야 합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 관리자 화면에 표시할 [AdminVote] 목록입니다.
  Future<List<AdminVote>> fetchVotes();

  /// 새 vote를 생성합니다.
  /// Controller는 이름만 넘기고 생성자나 endpoint 세부 처리는 구현체가 담당합니다.
  /// Parameters:
  /// - [name]: 생성할 vote 이름입니다.
  /// Returns:
  /// - [result]: 생성된 [AdminVote]입니다.
  Future<AdminVote> createVote({required String name});

  /// 단일 vote 상세 정보를 조회합니다.
  /// VoteDetailController가 question 목록과 운영 링크를 함께 구성하기 전 호출합니다.
  /// Parameters:
  /// - [voteId]: 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: 조회된 [AdminVote]입니다.
  Future<AdminVote> fetchVote(String voteId);

  /// 기존 vote의 이름이나 상태를 수정합니다.
  /// Mapper/Gateway 구현체가 서버 payload 차이를 흡수해야 합니다.
  /// Parameters:
  /// - [voteId]: 수정할 vote 식별자입니다.
  /// - [name]: 새 vote 이름입니다.
  /// - [status]: 새 진행 상태입니다.
  /// Returns:
  /// - [result]: 수정 후 [AdminVote]입니다.
  Future<AdminVote> updateVote({
    required String voteId,
    String? name,
    VoteStatus? status,
  });

  /// vote를 삭제합니다.
  /// Controller나 View는 endpoint 경로를 알지 않고 이 계약만 호출합니다.
  /// Parameters:
  /// - [voteId]: 삭제할 vote 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> deleteVote(String voteId);

  /// 특정 vote에 속한 question 목록을 조회합니다.
  /// Vote 목록의 count 계산과 상세 grid 렌더링에서 함께 사용됩니다.
  /// Parameters:
  /// - [voteId]: question을 조회할 vote 식별자입니다.
  /// Returns:
  /// - [result]: 해당 vote의 [AdminQuestion] 목록입니다.
  Future<List<AdminQuestion>> fetchQuestions(String voteId);

  /// 새 question을 생성합니다.
  /// 이미지 bytes는 포함하지 않고 업로드 결과의 URL과 ratio만 서버에 전달합니다.
  /// Parameters:
  /// - [voteId]: question이 속할 vote 식별자입니다.
  /// - [title]: question 제목입니다.
  /// - [detail]: question 설명입니다.
  /// - [imageUrl]: 업로드된 공개 이미지 URL입니다.
  /// - [imageRatio]: 이미지 가로/세로 비율입니다.
  /// Returns:
  /// - [result]: 생성된 [AdminQuestion]입니다.
  Future<AdminQuestion> createQuestion({
    required String voteId,
    required String title,
    required String detail,
    required String imageUrl,
    required double imageRatio,
  });

  /// 기존 question을 수정합니다.
  /// null이 아닌 값만 update payload로 반영하는 책임은 구현체에 있습니다.
  /// Parameters:
  /// - [questionId]: 수정할 question 식별자입니다.
  /// - [title]: 새 question 제목입니다.
  /// - [detail]: 새 question 설명입니다.
  /// - [imageUrl]: 새 공개 이미지 URL입니다.
  /// - [imageRatio]: 새 이미지 가로/세로 비율입니다.
  /// Returns:
  /// - [result]: 수정 후 [AdminQuestion]입니다.
  Future<AdminQuestion> updateQuestion({
    required String questionId,
    String? title,
    String? detail,
    String? imageUrl,
    double? imageRatio,
  });

  /// question을 삭제합니다.
  /// View와 Controller는 삭제 endpoint나 payload 형태를 알지 않습니다.
  /// Parameters:
  /// - [questionId]: 삭제할 question 식별자입니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> deleteQuestion(String questionId);

  /// public vote display payload를 조회해 player/participant 데이터 존재를 확인합니다.
  /// payload 구조는 공개 API 검증용으로 유지되고 Controller 밖에 generated DTO를 노출하지 않습니다.
  /// Parameters:
  /// - [voteId]: 공개 display를 확인할 vote 식별자입니다.
  /// Returns:
  /// - [result]: 공개 display API가 반환한 정규화 payload입니다.
  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId);

  /// public question payload를 조회해 participant/player가 읽을 데이터를 확인합니다.
  /// 구현체는 raw payload를 안정적인 map 목록으로 정규화합니다.
  /// Parameters:
  /// - [voteId]: 공개 question을 확인할 vote 식별자입니다.
  /// Returns:
  /// - [result]: 공개 question API의 정규화 payload 목록입니다.
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId);
}
