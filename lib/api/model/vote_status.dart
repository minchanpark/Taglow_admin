/// 관리자 앱에서 사용하는 vote 진행 상태 enum입니다.
/// Mapper가 서버 표현을 흡수하고 Controller와 View는 이 안정적인 값을 사용합니다.
/// fields:
/// - [progress]: 참여 가능한 진행 중 vote 상태입니다.
/// - [end]: 운영자가 종료한 vote 상태입니다.
enum VoteStatus {
  /// vote가 진행 중임을 나타냅니다.
  /// 서버 기본값이나 알 수 없는 상태가 이 값으로 정규화됩니다.
  progress,

  /// vote가 종료되었음을 나타냅니다.
  /// 참여자와 player 화면에서 종료 상태를 반영할 때 사용됩니다.
  end;

  /// 서버 payload에 보낼 상태 문자열을 반환합니다.
  /// Mapper가 update payload를 만들 때 enum과 서버 표현을 분리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 서버가 기대하는 vote 상태 문자열입니다.
  String get serverValue {
    switch (this) {
      case VoteStatus.progress:
        return 'PROGRESS';
      case VoteStatus.end:
        return 'END';
    }
  }

  /// 서버나 mock payload 값을 관리자 enum으로 정규화합니다.
  /// 알 수 없는 값은 운영 화면이 깨지지 않도록 진행 상태로 처리합니다.
  /// Parameters:
  /// - [value]: 서버 payload에서 읽은 상태 값입니다.
  /// Returns:
  /// - [result]: 앱 내부에서 사용할 [VoteStatus] 값입니다.
  static VoteStatus fromServerValue(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    switch (normalized) {
      case 'END':
        return VoteStatus.end;
      case 'PROGRESS':
      default:
        return VoteStatus.progress;
    }
  }
}
