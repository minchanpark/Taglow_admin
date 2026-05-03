import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/auth_controller.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

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
                        if (success && mounted) context.go('/login');
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
