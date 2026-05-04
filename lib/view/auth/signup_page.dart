import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/auth_controller.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

/// 관리자 계정 가입 요청 화면입니다.
/// 신규 사용자는 서버 정책상 USER로 생성되며 ADMIN 승격은 이 화면에서 수행하지 않습니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class SignupPage extends ConsumerStatefulWidget {
  /// 회원가입 화면 widget을 생성합니다.
  /// route builder가 `/signup`에서 이 widget을 렌더링합니다.
  /// Parameters:
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 회원가입 화면 widget 인스턴스입니다.
  const SignupPage({super.key});

  /// 회원가입 화면 state를 생성합니다.
  /// 입력 controller lifecycle과 auth Controller 호출을 state에서 관리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 회원가입 화면 state 객체입니다.
  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

/// 회원가입 form 입력과 제출 UI를 관리하는 state입니다.
/// password와 confirm 값은 submit validation에만 쓰고 Controller state에 보관하지 않습니다.
/// fields:
/// - [_nameController]: 아이디 입력 상태입니다.
/// - [_passwordController]: 비밀번호 입력 상태입니다.
/// - [_confirmController]: 비밀번호 확인 입력 상태입니다.
class _SignupPageState extends ConsumerState<SignupPage> {
  /// 아이디 입력을 보관하는 TextEditingController입니다.
  /// 길이 validation과 submit 가능 여부 계산에 사용됩니다.
  final _nameController = TextEditingController();

  /// 비밀번호 입력을 보관하는 TextEditingController입니다.
  /// 값은 회원가입 제출 시에만 [AuthController]로 전달됩니다.
  final _passwordController = TextEditingController();

  /// 비밀번호 확인 입력을 보관하는 TextEditingController입니다.
  /// Controller validation이 password와 일치 여부를 판단할 때 사용합니다.
  final _confirmController = TextEditingController();

  /// TextEditingController 자원을 해제합니다.
  /// 화면을 떠난 뒤 credential 입력값이 남지 않게 합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// 회원가입 화면 UI를 빌드합니다.
  /// [authControllerProvider] 상태로 제출 busy/error 표시를 하고 성공 시 login route로 이동합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: 회원가입 화면 widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final canSubmit =
        _nameController.text.trim().length >= 3 &&
        _passwordController.text.length >= 8 &&
        _confirmController.text.isNotEmpty;

    return AdminMobileShell(
      backgroundColor: AdminColors.surface,
      child: Column(
        children: <Widget>[
          AdminTopBar(title: '회원가입', onBack: () => context.go('/login')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '환영합니다.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '계정을 만들어 시작해보세요.',
                    style: TextStyle(
                      color: AdminColors.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  AdminTextInput(
                    label: '아이디',
                    controller: _nameController,
                    hintText: '3자 이상의 아이디',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 32),
                  AdminTextInput(
                    label: '비밀번호',
                    controller: _passwordController,
                    hintText: '8자 이상의 비밀번호',
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 32),
                  AdminTextInput(
                    label: '비밀번호 확인',
                    controller: _confirmController,
                    hintText: '비밀번호를 다시 입력하세요',
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (authState.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 24),
                    AdminMessage.error(authState.errorMessage!),
                  ],
                ],
              ),
            ),
          ),
          AdminBottomBar(
            height: 172,
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    AdminPrimaryButton(
                      label: '가입하기',
                      enabled: canSubmit,
                      isBusy: authState.isSubmitting,
                      onPressed: () async {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .signup(
                              name: _nameController.text,
                              password: _passwordController.text,
                              passwordConfirm: _confirmController.text,
                            );
                        if (!context.mounted) {
                          return;
                        }
                        if (success) context.go('/login');
                      },
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text.rich(
                        TextSpan(
                          text: '이미 계정이 있나요? ',
                          children: <InlineSpan>[
                            TextSpan(
                              text: '로그인',
                              style: TextStyle(
                                color: AdminColors.black,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: AdminColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
