import 'admin_user.dart';

/// 현재 관리자 인증 세션을 표현하는 domain model입니다.
/// Controller와 View가 로그인 여부와 ADMIN 권한을 안정적인 앱 모델로 판단하게 합니다.
/// fields:
/// - [user]: 인증된 관리자 후보 사용자이며, role 확인은 [AdminUser]에 위임됩니다.
/// - [isLoading]: 세션 확인 중임을 View에 전달하는 로딩 상태입니다.
/// - [errorMessage]: 세션 확인 실패를 화면 상태로 전달하는 메시지입니다.
class AdminAuthSession {
  /// 세션 상태를 불변 값으로 생성합니다.
  /// Service나 Controller가 현재 인증 결과를 View에 넘길 때 사용합니다.
  /// Parameters:
  /// - [user]: 현재 인증된 사용자이거나 비로그인 상태의 null입니다.
  /// - [isLoading]: 세션 조회가 진행 중인지 나타냅니다.
  /// - [errorMessage]: 조회 실패나 권한 오류를 설명하는 메시지입니다.
  /// Returns:
  /// - [instance]: 인증 세션 값을 보관하는 새 인스턴스입니다.
  const AdminAuthSession({
    required this.user,
    required this.isLoading,
    this.errorMessage,
  });

  /// 인증 서비스가 돌려준 현재 사용자입니다.
  /// [canManage]가 ADMIN 접근 가능 여부를 판단할 때 읽습니다.
  final AdminUser? user;

  /// 현재 사용자 조회나 세션 복구가 진행 중인지 나타냅니다.
  /// View는 이 값으로 초기 로딩 표시를 결정합니다.
  final bool isLoading;

  /// 인증 세션 확인 중 발생한 오류 메시지입니다.
  /// Controller가 사용자에게 보여줄 안전한 문구만 넣어야 합니다.
  final String? errorMessage;

  /// 로그인된 사용자가 있는지 계산합니다.
  /// 라우터와 View는 이 값을 통해 비로그인 상태를 빠르게 구분할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: [user]가 존재하는지 여부입니다.
  bool get isAuthenticated => user != null;

  /// 현재 사용자가 관리자 기능을 사용할 수 있는지 계산합니다.
  /// ADMIN role 판정은 [AdminUser.isAdmin]과 동기화됩니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 관리자 화면 진입 가능 여부입니다.
  bool get canManage => user?.isAdmin ?? false;
}
