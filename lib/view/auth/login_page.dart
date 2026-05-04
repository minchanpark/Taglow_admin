import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/auth_controller.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

/// 관리자 로그인 화면입니다.
/// 입력값은 [AuthController]로 제출하고 성공 시 vote 목록 route로 이동합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class LoginPage extends ConsumerStatefulWidget {
  /// 로그인 화면 widget을 생성합니다.
  /// route builder가 `/login`에서 이 widget을 렌더링합니다.
  /// Parameters:
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: 로그인 화면 widget 인스턴스입니다.
  const LoginPage({super.key});

  /// 로그인 화면 state를 생성합니다.
  /// text controller lifecycle과 Riverpod auth action 호출을 state에서 관리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: 로그인 화면 state 객체입니다.
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

/// 로그인 form 입력과 제출 UI를 관리하는 state입니다.
/// password는 controller 안에만 두고 submit 시 [AuthController.login]으로 즉시 전달합니다.
/// fields:
/// - [_nameController]: 아이디 TextField의 입력 상태입니다.
/// - [_passwordController]: 비밀번호 TextField의 입력 상태입니다.
class _LoginPageState extends ConsumerState<LoginPage> {
  /// 아이디 입력을 보관하는 TextEditingController입니다.
  /// 입력 변경 시 local submit 가능 여부를 다시 계산합니다.
  final _nameController = TextEditingController();

  /// 비밀번호 입력을 보관하는 TextEditingController입니다.
  /// 값은 화면 상태에만 머물며 Controller state에 저장하지 않습니다.
  final _passwordController = TextEditingController();

  /// TextEditingController 자원을 해제합니다.
  /// auth provider 상태는 Riverpod lifecycle이 관리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 로그인 화면 UI를 빌드합니다.
  /// [authControllerProvider] 상태로 busy/error/success 표시를 하고 성공 시 `/votes`로 이동합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: 로그인 화면 widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final canSubmit =
        _nameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;

    return AdminMobileShell(
      backgroundColor: AdminColors.surface,
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 92, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const TaglowLogo(),
                  const SizedBox(height: 62),
                  AdminTextInput(
                    label: '아이디',
                    controller: _nameController,
                    hintText: '아이디를 입력하세요',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 32),
                  AdminTextInput(
                    label: '비밀번호',
                    controller: _passwordController,
                    hintText: '비밀번호를 입력하세요',
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (authState.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 24),
                    AdminMessage.error(authState.errorMessage!),
                  ],
                  if (authState.successMessage != null) ...<Widget>[
                    const SizedBox(height: 24),
                    AdminMessage.success(authState.successMessage!),
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
                      label: '로그인',
                      enabled: canSubmit,
                      isBusy: authState.isSubmitting,
                      onPressed: () async {
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .login(
                              name: _nameController.text,
                              password: _passwordController.text,
                            );
                        if (!context.mounted) {
                          return;
                        }
                        if (success) context.go('/votes');
                      },
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text.rich(
                        TextSpan(
                          text: '아직 계정이 없나요? ',
                          children: <InlineSpan>[
                            TextSpan(
                              text: '회원가입',
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
