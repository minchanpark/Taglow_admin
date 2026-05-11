import '../model/admin_question.dart';
import '../model/admin_user.dart';
import '../model/admin_vote.dart';
import '../model/vote_status.dart';

/// 서버 payload와 관리자 domain model 사이 변환을 담당하는 Mapper입니다.
/// Gateway가 받은 raw map 구조와 Controller가 사용하는 model 계약 사이의 변화를 이 계층에서 흡수합니다.
/// 네트워크 호출, provider, Widget 의존성은 갖지 않습니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class AdminPayloadMapper {
  /// 상태 없는 payload mapper를 생성합니다.
  /// Service provider가 singleton처럼 재사용하거나 테스트에서 직접 주입할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: payload 변환을 수행하는 mapper 인스턴스입니다.
  const AdminPayloadMapper();

  /// backend `imageRatio`가 int64에서 double로 전환되기 전까지 사용하는 임시 스케일입니다.
  /// app 내부 domain model은 실제 width / height double 값을 유지합니다.
  static const int temporaryImageRatioScale = 10000;

  /// 로그인 입력값을 auth gateway payload로 변환합니다.
  /// Controller는 password를 상태에 보관하지 않고 Service가 즉시 이 payload로 넘깁니다.
  /// Parameters:
  /// - [name]: 로그인 사용자 이름 또는 아이디입니다.
  /// - [password]: 로그인 비밀번호입니다.
  /// Returns:
  /// - [result]: Gateway가 전송할 로그인 payload입니다.
  Map<String, Object?> loginToPayload({
    required String name,
    required String password,
  }) {
    return {'name': name, 'password': password};
  }

  /// 회원가입 입력값을 signup gateway payload로 변환합니다.
  /// ADMIN 승격 관련 값은 포함하지 않고 서버 기본 role 정책을 따릅니다.
  /// Parameters:
  /// - [name]: 가입할 사용자 이름 또는 아이디입니다.
  /// - [password]: 가입 비밀번호입니다.
  /// Returns:
  /// - [result]: Gateway가 전송할 회원가입 payload입니다.
  Map<String, Object?> signupToPayload({
    required String name,
    required String password,
  }) {
    return {'name': name, 'password': password};
  }

  /// auth payload를 [AdminUser] domain model로 변환합니다.
  /// 서버가 사용자 식별자를 서로 다른 이름으로 보내도 Controller에는 같은 model을 반환합니다.
  /// Parameters:
  /// - [payload]: Gateway가 정규화한 auth 사용자 payload입니다.
  /// Returns:
  /// - [result]: Controller가 사용할 [AdminUser]입니다.
  AdminUser userFromPayload(Map<String, Object?> payload) {
    return AdminUser(
      id: _string(payload['id'] ?? payload['userId']),
      name: _string(payload['name']),
      roles: _stringSet(payload['roles']),
    );
  }

  /// vote 생성 입력값을 gateway payload로 변환합니다.
  /// 생성자 식별자가 있을 때만 포함해 서버 endpoint 차이를 Service 내부에 둡니다.
  /// Parameters:
  /// - [name]: 생성할 vote 이름입니다.
  /// - [createdByUserId]: 현재 인증 사용자 식별자입니다.
  /// Returns:
  /// - [result]: null 값이 제거된 vote 생성 payload입니다.
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

  /// vote 수정 입력값을 gateway payload로 변환합니다.
  /// null 값은 제외하고 [VoteStatus]는 서버 문자열로 바꿉니다.
  /// Parameters:
  /// - [name]: 변경할 vote 이름입니다.
  /// - [status]: 변경할 vote 상태입니다.
  /// Returns:
  /// - [result]: null 값이 제거된 vote update payload입니다.
  Map<String, Object?> updateVoteToPayload({String? name, VoteStatus? status}) {
    return _withoutNulls({'name': name, 'status': status?.serverValue});
  }

  /// vote payload를 [AdminVote] domain model로 변환합니다.
  /// 서버 필드 alias와 status 표현 차이를 Mapper 내부에서 정규화합니다.
  /// Parameters:
  /// - [payload]: Gateway가 반환한 vote payload입니다.
  /// Returns:
  /// - [result]: Controller와 View가 사용할 [AdminVote]입니다.
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

  /// vote payload 목록을 domain model 목록으로 변환합니다.
  /// Service가 Gateway list 결과를 Controller-facing 값으로 바꿀 때 사용합니다.
  /// Parameters:
  /// - [payloads]: Gateway가 반환한 vote payload 목록입니다.
  /// Returns:
  /// - [result]: [AdminVote] domain model 목록입니다.
  List<AdminVote> votesFromPayloadList(List<Map<String, Object?>> payloads) {
    return payloads.map(voteFromPayload).toList(growable: false);
  }

  /// question 생성 입력값을 gateway payload로 변환합니다.
  /// 이미지 bytes는 포함하지 않고 공개 URL과 imageRatio만 서버 payload에 넣습니다.
  /// Parameters:
  /// - [voteId]: question이 속할 vote 식별자입니다.
  /// - [title]: question 제목입니다.
  /// - [detail]: question 설명입니다.
  /// - [imageUrl]: 업로드된 공개 이미지 URL입니다.
  /// - [imageRatio]: 이미지 가로/세로 비율입니다.
  /// Returns:
  /// - [result]: question 생성 payload입니다.
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
      'imageRatio': _encodeImageRatio(imageRatio),
    };
  }

  /// question 수정 입력값을 gateway payload로 변환합니다.
  /// null 값은 제외해 부분 수정 요청만 서버에 전달합니다.
  /// Parameters:
  /// - [title]: 변경할 question 제목입니다.
  /// - [detail]: 변경할 question 설명입니다.
  /// - [imageUrl]: 변경할 공개 이미지 URL입니다.
  /// - [imageRatio]: 변경할 이미지 비율입니다.
  /// Returns:
  /// - [result]: null 값이 제거된 question update payload입니다.
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
      'imageRatio': imageRatio == null ? null : _encodeImageRatio(imageRatio),
    });
  }

  /// question payload를 [AdminQuestion] domain model로 변환합니다.
  /// public preview 형태처럼 question이 중첩된 payload와 일반 payload를 모두 정규화합니다.
  /// Parameters:
  /// - [payload]: Gateway가 반환한 question payload입니다.
  /// Returns:
  /// - [result]: Controller와 View가 사용할 [AdminQuestion]입니다.
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
      imageRatio: _decodeImageRatio(normalized['imageRatio'], fallback: 1),
      createdAt: _date(normalized['createdAt']),
      updatedAt: _date(normalized['updatedAt']),
    );
  }

  /// question payload 목록을 domain model 목록으로 변환합니다.
  /// Service가 question list API 결과를 Controller-facing 값으로 바꿀 때 사용합니다.
  /// Parameters:
  /// - [payloads]: Gateway가 반환한 question payload 목록입니다.
  /// Returns:
  /// - [result]: [AdminQuestion] domain model 목록입니다.
  List<AdminQuestion> questionsFromPayloadList(
    List<Map<String, Object?>> payloads,
  ) {
    return payloads.map(questionFromPayload).toList(growable: false);
  }

  /// nullable payload 값을 문자열로 정규화합니다.
  /// 서버 값이 빠진 경우 빈 문자열을 반환해 domain model 생성을 안정화합니다.
  /// Parameters:
  /// - [value]: 서버 payload에서 읽은 값입니다.
  /// Returns:
  /// - [result]: 문자열로 변환된 값 또는 빈 문자열입니다.
  String _string(Object? value) => value?.toString() ?? '';

  /// payload role 값을 문자열 집합으로 정규화합니다.
  /// Auth Controller가 USER/ADMIN role을 같은 방식으로 판단하도록 보장합니다.
  /// Parameters:
  /// - [value]: 서버 payload의 role 목록 값입니다.
  /// Returns:
  /// - [result]: 문자열 role 집합입니다.
  Set<String> _stringSet(Object? value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toSet();
    }
    return const <String>{};
  }

  /// payload 시간 값을 [DateTime]으로 파싱합니다.
  /// 서버 값이 없거나 형식이 맞지 않으면 null로 두어 View가 fallback을 표시하게 합니다.
  /// Parameters:
  /// - [value]: 서버 payload의 시간 값입니다.
  /// Returns:
  /// - [result]: 파싱된 [DateTime] 또는 null입니다.
  DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// payload 숫자 값을 double로 정규화합니다.
  /// imageRatio가 integer 또는 string으로 와도 domain model은 double을 유지합니다.
  /// Parameters:
  /// - [value]: 서버 payload의 숫자 값입니다.
  /// - [fallback]: 파싱 실패 시 사용할 기본값입니다.
  /// Returns:
  /// - [result]: double로 정규화된 값입니다.
  double _double(Object? value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  /// 실제 imageRatio double 값을 backend int64 계약에 맞는 임시 정수로 변환합니다.
  /// Parameters:
  /// - [value]: width / height로 계산된 실제 이미지 비율입니다.
  /// Returns:
  /// - [result]: 서버 payload에 넣을 scaled integer 비율입니다.
  int _encodeImageRatio(double value) {
    return (value * temporaryImageRatioScale).round();
  }

  /// backend가 임시 정수로 돌려준 imageRatio를 domain double 값으로 복원합니다.
  /// 아직 double 값을 반환하는 mock/미래 backend와 오래된 작은 정수 값도 허용합니다.
  /// Parameters:
  /// - [value]: 서버 payload의 imageRatio 값입니다.
  /// - [fallback]: 파싱 실패 시 사용할 기본값입니다.
  /// Returns:
  /// - [result]: app 내부에서 사용할 실제 이미지 비율입니다.
  double _decodeImageRatio(Object? value, {required double fallback}) {
    final parsed = _double(value, fallback: fallback);
    if (parsed.abs() > 20) {
      return parsed / temporaryImageRatioScale;
    }
    return parsed;
  }

  /// 문자열 id를 서버가 받을 수 있는 숫자 또는 문자열 값으로 변환합니다.
  /// mock과 real API가 id 타입 차이를 가져도 payload 생성 지점을 한 곳으로 둡니다.
  /// Parameters:
  /// - [value]: domain model이나 Controller에서 받은 문자열 id입니다.
  /// Returns:
  /// - [result]: 정수로 파싱된 값 또는 원래 문자열입니다.
  Object _intOrString(String value) {
    return int.tryParse(value) ?? value;
  }

  /// payload map에서 null 값을 제거합니다.
  /// 부분 update 요청이 의도하지 않은 null overwrite를 만들지 않게 보호합니다.
  /// Parameters:
  /// - [value]: 원본 payload map입니다.
  /// Returns:
  /// - [result]: null entry가 제거된 payload map입니다.
  Map<String, Object?> _withoutNulls(Map<String, Object?> value) {
    return Map.fromEntries(value.entries.where((entry) => entry.value != null));
  }
}
