import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/admin_user.dart';
import '../service/admin_service.dart';
import '../service/admin_service_provider.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(adminServiceProvider));
  },
);

class AuthState {
  const AuthState({
    this.user,
    this.isCheckingSession = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  final AdminUser? user;
  final bool isCheckingSession;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  bool get isAuthenticated => user != null;
  bool get canManage => user?.isAdmin ?? false;

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

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service) : super(const AuthState());

  final AdminService _service;

  Future<void> checkSession() async {
    state = state.copyWith(
      isCheckingSession: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final user = await _service.fetchCurrentUser();
      state = state.copyWith(
        user: user != null && user.isAdmin ? user : null,
        clearUser: user == null || !user.isAdmin,
        isCheckingSession: false,
      );
    } catch (_) {
      state = state.copyWith(clearUser: true, isCheckingSession: false);
    }
  }

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
      if (!user.isAdmin) {
        await _logoutQuietly();
        state = state.copyWith(
          clearUser: true,
          isSubmitting: false,
          errorMessage: '관리자 권한이 필요합니다.',
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
        successMessage: '회원가입이 완료되었습니다. 최고 관리자 승인 후 관리자 기능을 사용할 수 있습니다.',
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

  Future<void> logout() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _service.logout();
    } finally {
      state = state.copyWith(clearUser: true, isSubmitting: false);
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> _logoutQuietly() async {
    try {
      await _service.logout();
    } catch (_) {}
  }

  String? _validateLogin({required String name, required String password}) {
    if (name.trim().isEmpty) return '아이디를 입력해주세요.';
    if (password.isEmpty) return '비밀번호를 입력해주세요.';
    return null;
  }

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

  String _message(Object error, {required String fallback}) {
    final text = error.toString();
    return text.isEmpty ? fallback : text;
  }
}
