import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/vote_list_controller.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

class VoteCreatePage extends ConsumerStatefulWidget {
  const VoteCreatePage({super.key});

  @override
  ConsumerState<VoteCreatePage> createState() => _VoteCreatePageState();
}

class _VoteCreatePageState extends ConsumerState<VoteCreatePage> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
                    if (vote != null && mounted) {
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
