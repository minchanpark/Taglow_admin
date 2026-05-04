import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/vote_list_controller.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

/// 새 vote를 생성하는 화면입니다.
/// 입력값은 [VoteListController.createVote]로 전달하고 성공 시 question 추가 화면으로 이동합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class VoteCreatePage extends ConsumerStatefulWidget {
  /// vote 생성 화면 widget을 생성합니다.
  /// route builder가 `/votes/new`에서 이 widget을 렌더링합니다.
  /// Parameters:
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: vote 생성 화면 widget 인스턴스입니다.
  const VoteCreatePage({super.key});

  /// vote 생성 화면 state를 생성합니다.
  /// TextEditingController lifecycle과 create action 결과 처리를 state에서 관리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: vote 생성 화면 state 객체입니다.
  @override
  ConsumerState<VoteCreatePage> createState() => _VoteCreatePageState();
}

/// vote 이름 입력과 생성 action UI를 관리하는 state입니다.
/// 실제 생성은 [voteListControllerProvider]의 Controller에 위임합니다.
/// fields:
/// - [_nameController]: vote 이름 입력 상태입니다.
class _VoteCreatePageState extends ConsumerState<VoteCreatePage> {
  /// vote 이름 입력을 보관하는 TextEditingController입니다.
  /// local submit 가능 여부와 Controller create 호출에 사용됩니다.
  final _nameController = TextEditingController();

  /// vote 이름 입력 controller 자원을 해제합니다.
  /// 생성 결과 상태는 Riverpod Controller lifecycle이 관리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// vote 생성 화면 UI를 빌드합니다.
  /// [VoteListState]의 submitting/error 상태를 버튼과 메시지에 반영합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: vote 생성 화면 widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voteListControllerProvider);
    final canSubmit = _nameController.text.trim().isNotEmpty;

    return AdminMobileShell(
      backgroundColor: AdminColors.surface,
      child: Column(
        children: <Widget>[
          AdminTopBar(title: '새 투표 생성', onBack: () => context.go('/votes')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '어떤 투표를\n만드시겠어요?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 56),
                  AdminTextInput(
                    label: '투표 제목',
                    controller: _nameController,
                    hintText: '예: 벤쳐러스 방명록',
                    large: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (state.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 24),
                    AdminMessage.error(state.errorMessage!),
                  ],
                ],
              ),
            ),
          ),
          AdminBottomBar(
            children: <Widget>[
              Expanded(
                child: AdminPrimaryButton(
                  label: '다음 단계로',
                  enabled: canSubmit,
                  isBusy: state.isSubmitting,
                  onPressed: () async {
                    final vote = await ref
                        .read(voteListControllerProvider.notifier)
                        .createVote(_nameController.text);
                    if (!context.mounted) {
                      return;
                    }
                    if (vote != null) {
                      context.go('/votes/${vote.id}/questions/new');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
