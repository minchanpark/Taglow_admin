/// vote에 속한 question을 관리자 앱 내부에서 표현하는 domain model입니다.
/// Controller, Service, Mapper, View가 generated DTO 대신 공유하는 안정적인 형태입니다.
/// fields:
/// - [id]: question을 식별하며 update/delete와 View key에 사용됩니다.
/// - [voteId]: 이 question이 연결된 vote 식별자이며 상세 화면과 저장 요청에 사용됩니다.
/// - [title]: 운영자가 입력한 question 표시 제목입니다.
/// - [detail]: 참여자와 player 화면에서 사용할 question 설명입니다.
/// - [imageUrl]: 업로드 완료 후 서버 payload로 전달되는 공개 이미지 URL입니다.
/// - [imageRatio]: 이미지 bounds 계산을 위해 저장되는 원본 가로/세로 비율입니다.
/// - [createdAt]: 서버나 mock service가 제공하는 생성 시각입니다.
/// - [updatedAt]: 수정 흐름에서 View가 참고할 수 있는 갱신 시각입니다.
class AdminQuestion {
  /// question domain 값을 생성합니다.
  /// Mapper와 Mock service가 서버 payload나 fixture를 앱 모델로 고정할 때 사용합니다.
  /// Parameters:
  /// - [id]: question 식별자입니다.
  /// - [voteId]: 소속 vote 식별자입니다.
  /// - [title]: 운영자가 보는 question 제목입니다.
  /// - [detail]: question 설명 또는 보조 문구입니다.
  /// - [imageUrl]: 업로드된 이미지의 공개 URL입니다.
  /// - [imageRatio]: 이미지의 가로/세로 비율입니다.
  /// - [createdAt]: 생성 시각입니다.
  /// - [updatedAt]: 갱신 시각입니다.
  /// Returns:
  /// - [instance]: question 정보를 보관하는 새 인스턴스입니다.
  const AdminQuestion({
    required this.id,
    required this.voteId,
    required this.title,
    required this.detail,
    required this.imageUrl,
    required this.imageRatio,
    this.createdAt,
    this.updatedAt,
  });

  /// question의 안정적인 식별자입니다.
  /// Service의 update/delete와 View의 항목 표시에서 사용됩니다.
  final String id;

  /// 이 question이 속한 vote 식별자입니다.
  /// 저장 payload와 상세 화면의 question 묶음을 연결합니다.
  final String voteId;

  /// 운영자가 입력한 question 제목입니다.
  /// 목록과 상세 View에서 주요 표시 텍스트로 사용됩니다.
  final String title;

  /// question에 붙는 설명 문구입니다.
  /// Mapper가 서버 payload 차이를 흡수한 뒤 이 필드로 고정합니다.
  final String detail;

  /// question 이미지의 공개 URL입니다.
  /// 서버에는 bytes가 아니라 이 URL만 전달되어야 합니다.
  final String imageUrl;

  /// question 이미지의 원본 가로/세로 비율입니다.
  /// 참여자 화면과 player 화면의 반응형 이미지 계산과 동기화됩니다.
  final double imageRatio;

  /// question 생성 시각입니다.
  /// 서버 값이 없을 수 있어 null을 허용합니다.
  final DateTime? createdAt;

  /// question 갱신 시각입니다.
  /// 수정 API나 mock service 결과를 View에 전달할 때 사용됩니다.
  final DateTime? updatedAt;

  /// 기존 question에서 일부 값만 교체한 새 모델을 만듭니다.
  /// Mock service와 수정 흐름이 불변 모델을 유지하면서 상태를 갱신할 때 사용합니다.
  /// Parameters:
  /// - [id]: 교체할 question 식별자입니다.
  /// - [voteId]: 교체할 vote 식별자입니다.
  /// - [title]: 교체할 제목입니다.
  /// - [detail]: 교체할 설명입니다.
  /// - [imageUrl]: 교체할 공개 이미지 URL입니다.
  /// - [imageRatio]: 교체할 이미지 비율입니다.
  /// - [createdAt]: 교체할 생성 시각입니다.
  /// - [updatedAt]: 교체할 갱신 시각입니다.
  /// Returns:
  /// - [result]: 변경값이 반영된 새 [AdminQuestion]입니다.
  AdminQuestion copyWith({
    String? id,
    String? voteId,
    String? title,
    String? detail,
    String? imageUrl,
    double? imageRatio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminQuestion(
      id: id ?? this.id,
      voteId: voteId ?? this.voteId,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      imageUrl: imageUrl ?? this.imageUrl,
      imageRatio: imageRatio ?? this.imageRatio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
