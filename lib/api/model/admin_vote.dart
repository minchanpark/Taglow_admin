import 'vote_status.dart';

/// 운영자가 관리하는 vote를 표현하는 관리자 domain model입니다.
/// Controller, Service, Mapper, View가 vote 목록과 상세 상태를 공유할 때 사용합니다.
/// fields:
/// - [id]: vote 식별자이며 question, participant link, player link 생성의 기준입니다.
/// - [name]: 운영자가 입력한 vote 표시 이름입니다.
/// - [status]: 진행 또는 종료 상태를 나타내는 앱 enum입니다.
/// - [createdByUserId]: vote 생성자 식별자로 서버 payload와 mapper가 관리합니다.
/// - [isMine]: 현재 사용자 소유 여부를 View 정책에 전달하는 플래그입니다.
/// - [createdAt]: 목록 날짜 표시에 사용되는 생성 시각입니다.
/// - [updatedAt]: 수정 흐름에서 사용할 수 있는 갱신 시각입니다.
class AdminVote {
  /// vote domain 값을 생성합니다.
  /// Mapper와 mock service가 서버 결과를 안정적인 앱 모델로 바꿀 때 사용합니다.
  /// Parameters:
  /// - [id]: vote 식별자입니다.
  /// - [name]: vote 이름입니다.
  /// - [status]: vote 진행 상태입니다.
  /// - [createdByUserId]: 생성자 사용자 식별자입니다.
  /// - [isMine]: 현재 사용자 소유 여부입니다.
  /// - [createdAt]: 생성 시각입니다.
  /// - [updatedAt]: 갱신 시각입니다.
  /// Returns:
  /// - [instance]: vote 정보를 보관하는 새 인스턴스입니다.
  const AdminVote({
    required this.id,
    required this.name,
    required this.status,
    required this.createdByUserId,
    this.isMine = false,
    this.createdAt,
    this.updatedAt,
  });

  /// vote의 안정적인 식별자입니다.
  /// URL builder와 question 조회가 이 값을 기준으로 동작합니다.
  final String id;

  /// 운영자가 보는 vote 이름입니다.
  /// 목록 카드와 상세 top bar의 주요 텍스트로 쓰입니다.
  final String name;

  /// vote의 진행 상태입니다.
  /// Mapper가 서버 값을 [VoteStatus]로 정규화해 저장합니다.
  final VoteStatus status;

  /// vote를 만든 사용자 식별자입니다.
  /// 생성 payload나 소유자 정책과 연결될 수 있는 domain 값입니다.
  final String createdByUserId;

  /// 현재 로그인 사용자와의 소유 관계입니다.
  /// View나 Controller가 권한별 action을 조정할 때 사용할 수 있습니다.
  final bool isMine;

  /// vote 생성 시각입니다.
  /// [formatAdminDate] 같은 View helper가 목록 표시로 사용합니다.
  final DateTime? createdAt;

  /// vote 갱신 시각입니다.
  /// 수정 결과를 불변 모델에 반영할 때 유지됩니다.
  final DateTime? updatedAt;

  /// 기존 vote에서 일부 필드만 바꾼 새 모델을 만듭니다.
  /// Service 구현이 불변 상태를 유지하며 update 결과를 구성할 때 사용합니다.
  /// Parameters:
  /// - [id]: 교체할 vote 식별자입니다.
  /// - [name]: 교체할 vote 이름입니다.
  /// - [status]: 교체할 진행 상태입니다.
  /// - [createdByUserId]: 교체할 생성자 식별자입니다.
  /// - [isMine]: 교체할 소유 여부입니다.
  /// - [createdAt]: 교체할 생성 시각입니다.
  /// - [updatedAt]: 교체할 갱신 시각입니다.
  /// Returns:
  /// - [result]: 변경값이 반영된 새 [AdminVote]입니다.
  AdminVote copyWith({
    String? id,
    String? name,
    VoteStatus? status,
    String? createdByUserId,
    bool? isMine,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminVote(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      isMine: isMine ?? this.isMine,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
