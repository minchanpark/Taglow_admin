/// 관리자 인증 결과로 사용하는 사용자 domain model입니다.
/// Auth Controller와 라우터가 generated DTO 없이 ADMIN role을 판단하게 합니다.
/// fields:
/// - [id]: 서버 사용자 식별자이며 vote 생성자의 연결값으로 전달될 수 있습니다.
/// - [name]: 관리자 화면에서 식별 가능한 사용자 이름입니다.
/// - [roles]: 서버가 부여한 role 집합이며 [isAdmin]이 접근 가능 여부를 계산합니다.
class AdminUser {
  /// 사용자 인증 정보를 불변 값으로 생성합니다.
  /// Mapper와 mock service가 auth 결과를 Controller에 넘길 때 사용합니다.
  /// Parameters:
  /// - [id]: 사용자 식별자입니다.
  /// - [name]: 로그인 이름 또는 표시 이름입니다.
  /// - [roles]: 사용자 권한 role 집합입니다.
  /// Returns:
  /// - [instance]: 사용자 권한 정보를 보관하는 새 인스턴스입니다.
  const AdminUser({required this.id, required this.name, required this.roles});

  /// 서버가 제공한 사용자 식별자입니다.
  /// vote 생성 payload와 mock service 소유자 값에서 참조됩니다.
  final String id;

  /// 로그인에 사용되는 관리자 이름입니다.
  /// 인증 상태 표시나 디버그용 domain 값으로 유지됩니다.
  final String name;

  /// 사용자가 가진 role 집합입니다.
  /// 클라이언트는 이 값을 읽기만 하며 ADMIN 승격을 수행하지 않습니다.
  final Set<String> roles;

  /// 사용자가 ADMIN role을 갖는지 계산합니다.
  /// Auth Controller와 라우터 보호 로직이 같은 기준을 공유합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: ADMIN 권한 보유 여부입니다.
  bool get isAdmin => roles.contains('ADMIN');
}
