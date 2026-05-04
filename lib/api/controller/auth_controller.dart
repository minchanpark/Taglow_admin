import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/admin_user.dart';
import '../service/admin_service.dart';
import '../service/admin_service_provider.dart';

/// 인증 상태를 제공하는 Riverpod provider입니다.
/// View와 router가 [AuthState]를 구독하고, 실제 auth 동작은 [AdminService]를 통해 수행됩니다.
/// 콘솔 접근 role 확인은 Controller에 모아 UI가 서버 payload나 auth endpoint를 알지 않게 합니다.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(adminServiceProvider));
  },
);

/// 관리자 로그인, 세션 확인, 가입 흐름의 UI 상태입니다.
/// Login/Signup View와 router guard가 이 상태만 읽고 auth Service 세부 구현은 알지 않습니다.
/// fields:
/// - [user]: 현재 인증된 운영자 후보 사용자이며 콘솔 접근 여부는 [canManage]로 계산됩니다.
/// - [isCheckingSession]: 앱 시작 시 기존 세션 확인 중인지 나타냅니다.
/// - [isSubmitting]: 로그인, 회원가입, 로그아웃 요청이 진행 중인지 나타냅니다.
/// - [errorMessage]: View에 표시할 인증 실패 또는 권한 오류 메시지입니다.
/// - [successMessage]: 회원가입 완료 같은 성공 피드백 메시지입니다.
class AuthState {
  /// 인증 화면이 사용할 상태 값을 생성합니다.
  /// Controller가 불변 상태를 교체하며 View에 로딩, 오류, 성공 메시지를 전달합니다.
  /// Parameters:
  /// - [user]: 현재 인증된 사용자입니다.
  /// - [isCheckingSession]: 세션 확인 로딩 여부입니다.
  /// - [isSubmitting]: form 제출 또는 로그아웃 진행 여부입니다.
  /// - [errorMessage]: 사용자에게 표시할 오류 메시지입니다.
  /// - [successMessage]: 사용자에게 표시할 성공 메시지입니다.
  /// Returns:
  /// - [instance]: 인증 UI 상태를 보관하는 새 인스턴스입니다.
  const AuthState({
    this.user,
    this.isCheckingSession = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  /// 현재 인증된 사용자입니다.
  /// 콘솔 접근 role이 없으면 Controller가 null로 정리해 관리자 진입을 막습니다.
  final AdminUser? user;

  /// 기존 Spring session이나 token 세션을 확인 중인지 나타냅니다.
  /// 앱 bootstrap과 router 전환의 초기 로딩 판단에 쓰입니다.
  final bool isCheckingSession;

  /// 로그인, 회원가입, 로그아웃 요청이 진행 중인지 나타냅니다.
  /// Auth View의 버튼 busy/disabled 상태와 연결됩니다.
  final bool isSubmitting;

  /// 인증 실패, 권한 부족, validation 실패를 담는 화면용 메시지입니다.
  /// 비밀번호나 token 같은 민감한 값은 포함하지 않아야 합니다.
  final String? errorMessage;

  /// 가입 완료처럼 다음 행동을 안내하는 성공 메시지입니다.
  /// LoginPage와 SignupPage가 같은 provider 상태에서 읽습니다.
  final String? successMessage;

  /// 인증된 사용자가 있는지 계산합니다.
  /// 라우터와 View는 이 값으로 로그인 상태를 빠르게 확인할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: [user] 존재 여부입니다.
  bool get isAuthenticated => user != null;

  /// 현재 사용자가 관리자 기능에 진입할 수 있는지 계산합니다.
  /// USER와 ADMIN role 모두 운영 콘솔 접근을 허용합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 관리자 route 접근 가능 여부입니다.
  bool get canManage => user?.canUseAdminConsole ?? false;

  /// 일부 인증 상태만 교체한 새 [AuthState]를 만듭니다.
  /// Controller가 로딩, 오류, 성공 메시지를 명시적으로 지우며 상태를 갱신할 때 사용합니다.
  /// Parameters:
  /// - [user]: 새로 반영할 인증 사용자입니다.
  /// - [clearUser]: 기존 사용자를 null로 지울지 결정합니다.
  /// - [isCheckingSession]: 세션 확인 로딩 상태입니다.
  /// - [isSubmitting]: 제출 로딩 상태입니다.
  /// - [errorMessage]: 새 오류 메시지입니다.
  /// - [clearError]: 기존 오류 메시지를 지울지 결정합니다.
  /// - [successMessage]: 새 성공 메시지입니다.
  /// - [clearSuccess]: 기존 성공 메시지를 지울지 결정합니다.
  /// Returns:
  /// - [result]: 변경값이 반영된 새 [AuthState]입니다.
  AuthState copyWith({
    AdminUser? user,
    bool clearUser = false,
    bool? isCheckingSession,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

/// 인증 관련 사용자 이벤트를 처리하는 Controller입니다.
/// Auth View는 이 객체의 메서드만 호출하고 실제 API 호출은 [AdminService] 경계 뒤에 둡니다.
/// 콘솔 접근 role이 없으면 즉시 세션을 정리해 관리자 화면 진입을 막습니다.
/// fields:
/// - [_service]: auth, signup, session, logout API 흐름을 감싼 Service 계약입니다.
class AuthController extends StateNotifier<AuthState> {
  /// 인증 Controller를 생성하고 빈 인증 상태로 시작합니다.
  /// [authControllerProvider]가 [AdminService] 구현을 주입합니다.
  /// Parameters:
  /// - [_service]: 인증 API를 수행하는 service 계약입니다.
  /// Returns:
  /// - [instance]: 인증 상태를 관리하는 새 Controller입니다.
  AuthController(this._service) : super(const AuthState());

  /// 인증 API와 세션 정리를 수행하는 Service 의존성입니다.
  /// Controller가 endpoint나 generated client를 직접 알지 않게 합니다.
  final AdminService _service;

  /// 앱 시작 시 현재 인증 세션과 콘솔 접근 권한을 확인합니다.
  /// USER 또는 ADMIN role이 있는 사용자만 상태에 보관하고 나머지는 비로그인처럼 정리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> checkSession() async {
    state = state.copyWith(
      isCheckingSession: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final user = await _service.fetchCurrentUser();
      state = state.copyWith(
        user: user != null && user.canUseAdminConsole ? user : null,
        clearUser: user == null || !user.canUseAdminConsole,
        isCheckingSession: false,
      );
    } catch (_) {
      state = state.copyWith(clearUser: true, isCheckingSession: false);
    }
  }

  /// 로그인 form 값을 검증한 뒤 인증 Service에 로그인 요청을 보냅니다.
  /// USER 또는 ADMIN role이면 운영 콘솔 진입을 허용합니다.
  /// Parameters:
  /// - [name]: LoginPage에서 입력한 관리자 아이디입니다.
  /// - [password]: LoginPage에서 입력한 비밀번호이며 상태에 저장하지 않습니다.
  /// Returns:
  /// - [result]: 로그인과 콘솔 접근 권한 확인이 모두 성공했는지 여부입니다.
  Future<bool> login({required String name, required String password}) async {
    final validationError = _validateLogin(name: name, password: password);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError, clearSuccess: true);
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final user = await _service.login(name: name.trim(), password: password);
      if (!user.canUseAdminConsole) {
        state = state.copyWith(
          clearUser: true,
          isSubmitting: false,
          errorMessage: '운영 콘솔 접근 권한이 없습니다.',
        );
        return false;
      }
      state = state.copyWith(user: user, isSubmitting: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        clearUser: true,
        isSubmitting: false,
        errorMessage: _message(error, fallback: '로그인에 실패했습니다.'),
      );
      return false;
    }
  }

  /// 신규 계정 생성을 요청하고 성공 안내 메시지를 상태에 반영합니다.
  /// 서버 정책상 신규 사용자는 USER로 생성되며 Controller는 ADMIN 승격을 수행하지 않습니다.
  /// Parameters:
  /// - [name]: SignupPage에서 입력한 아이디입니다.
  /// - [password]: SignupPage에서 입력한 비밀번호이며 상태에 보관하지 않습니다.
  /// - [passwordConfirm]: 클라이언트 validation에만 쓰는 비밀번호 확인값입니다.
  /// Returns:
  /// - [result]: 회원가입 요청이 성공했는지 여부입니다.
  Future<bool> signup({
    required String name,
    required String password,
    required String passwordConfirm,
  }) async {
    final validationError = _validateSignup(
      name: name,
      password: password,
      passwordConfirm: passwordConfirm,
    );
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError, clearSuccess: true);
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.signup(name: name.trim(), password: password);
      state = state.copyWith(
        clearUser: true,
        isSubmitting: false,
        successMessage: '회원가입이 완료되었습니다. 로그인 후 운영 콘솔을 사용할 수 있습니다.',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _message(error, fallback: '회원가입에 실패했습니다.'),
      );
      return false;
    }
  }

  /// 현재 관리자 세션을 종료합니다.
  /// Service logout이 실패하더라도 로컬 auth 상태는 비로그인 상태로 정리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> logout() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _service.logout();
    } finally {
      state = state.copyWith(clearUser: true, isSubmitting: false);
    }
  }

  /// 현재 표시 중인 오류와 성공 메시지를 지웁니다.
  /// View가 화면 전환이나 입력 변경 시 이전 피드백을 정리할 때 사용할 수 있습니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// 로그인 입력값의 최소 조건을 검증합니다.
  /// 비밀번호 내용은 상태나 로그에 남기지 않고 메시지만 반환합니다.
  /// Parameters:
  /// - [name]: 로그인 아이디 입력값입니다.
  /// - [password]: 로그인 비밀번호 입력값입니다.
  /// Returns:
  /// - [result]: validation 실패 메시지이거나 통과 시 null입니다.
  String? _validateLogin({required String name, required String password}) {
    if (name.trim().isEmpty) return '아이디를 입력해주세요.';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    return null;
  }

  /// 회원가입 입력값의 길이와 비밀번호 일치 여부를 검증합니다.
  /// 서버 role 정책은 Service 결과를 통해 처리하고 여기서는 form 안전성만 확인합니다.
  /// Parameters:
  /// - [name]: 회원가입 아이디 입력값입니다.
  /// - [password]: 회원가입 비밀번호 입력값입니다.
  /// - [passwordConfirm]: 비밀번호 확인 입력값입니다.
  /// Returns:
  /// - [result]: validation 실패 메시지이거나 통과 시 null입니다.
  String? _validateSignup({
    required String name,
    required String password,
    required String passwordConfirm,
  }) {
    if (name.trim().length < 3) return '아이디는 3자 이상이어야 합니다.';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    if (password != passwordConfirm) return '비밀번호가 일치하지 않습니다.';
    return null;
  }

  /// 예외 객체를 View에 표시할 메시지로 정규화합니다.
  /// 빈 오류 문자열이면 호출자가 지정한 fallback 문구를 사용합니다.
  /// Parameters:
  /// - [error]: Service나 validation 흐름에서 발생한 오류 객체입니다.
  /// - [fallback]: 오류 문자열이 비어 있을 때 사용할 기본 메시지입니다.
  /// Returns:
  /// - [result]: 사용자에게 표시할 오류 메시지입니다.
  String _message(Object error, {required String fallback}) {
    final text = error.toString();
    return text.isEmpty ? fallback : text;
  }
}
