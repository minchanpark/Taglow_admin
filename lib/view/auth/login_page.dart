import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/auth_controller.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                        if (success && mounted) context.go('/votes');
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
