import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/vote_detail_controller.dart';
import '../../api/model/admin_question.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

class VoteDetailPage extends ConsumerStatefulWidget {
  const VoteDetailPage({required this.voteId, super.key});

  final String voteId;

  @override
  ConsumerState<VoteDetailPage> createState() => _VoteDetailPageState();
}

class _VoteDetailPageState extends ConsumerState<VoteDetailPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () =>
          ref.read(voteDetailControllerProvider(widget.voteId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voteDetailControllerProvider(widget.voteId));
    final voteName = state.vote?.name ?? '투표 상세';

    return AdminMobileShell(
      child: Column(
        children: <Widget>[
          AdminTopBar(
            title: voteName,
            onBack: () => context.go('/votes'),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.share_outlined),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(voteDetailControllerProvider(widget.voteId).notifier)
                  .load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                children: <Widget>[
                  const Text(
                    '세부 항목 관리',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '총 ${state.questions.length}개의 세부 항목이 있습니다.',
                    style: const TextStyle(
                      color: AdminColors.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (state.isLoading)
                    const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.errorMessage != null)
                    AdminMessage.error(state.errorMessage!)
                  else
                    _QuestionGrid(
                      questions: state.questions,
                      onAdd: () =>
                          context.go('/votes/${widget.voteId}/questions/new'),
                    ),
                  if (state.links != null) ...<Widget>[
                    const SizedBox(height: 28),
                    _LinkPanel(
                      label: '참여자 링크',
                      value: state.links!.participantUrl,
                    ),
                    const SizedBox(height: 12),
                    _LinkPanel(label: '플레이어 링크', value: state.links!.playerUrl),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionGrid extends StatelessWidget {
  const _QuestionGrid({required this.questions, required this.onAdd});

  final List<AdminQuestion> questions;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      ...questions.map((question) => _QuestionTile(question: question)),
      SizedBox(
        height: 164,
        child: AddTile(label: '항목 추가', onTap: onAdd),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question});

  final AdminQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 42),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            question.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: const Text(
              '0명 참여',
              style: TextStyle(
                color: AdminColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkPanel extends StatelessWidget {
  const _LinkPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AdminColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
