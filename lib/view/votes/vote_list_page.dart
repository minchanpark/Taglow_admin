import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/vote_list_controller.dart';
import '../../api/model/admin_vote.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

class VoteListPage extends ConsumerStatefulWidget {
  const VoteListPage({super.key});

  @override
  ConsumerState<VoteListPage> createState() => _VoteListPageState();
}

class _VoteListPageState extends ConsumerState<VoteListPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(voteListControllerProvider.notifier).loadVotes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voteListControllerProvider);

    return AdminMobileShell(
      child: Column(
        children: <Widget>[
          Container(
            height: 140,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: const BoxDecoration(
              color: AdminColors.surface,
              border: Border(bottom: BorderSide(color: AdminColors.softLine)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  '투표 관리',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.5,
                  ),
                ),
                Text(
                  '총 ${state.votes.length}개의 카테고리',
                  style: const TextStyle(
                    color: AdminColors.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(voteListControllerProvider.notifier).loadVotes(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                children: <Widget>[
                  if (state.isLoading)
                    const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.errorMessage != null)
                    AdminMessage.error(state.errorMessage!)
                  else if (state.isEmpty)
                    const _EmptyVotes()
                  else
                    ...state.votes.map(
                      (vote) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _VoteCard(
                          vote: vote,
                          questionCount: state.questionCounts[vote.id] ?? 0,
                          onTap: () => context.go('/votes/${vote.id}'),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 140,
                    child: AddTile(
                      label: '새로운 투표 만들기',
                      onTap: () => context.go('/votes/new'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({
    required this.vote,
    required this.questionCount,
    required this.onTap,
  });

  final AdminVote vote;
  final int questionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AdminColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    vote.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AdminColors.softLine,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '세부 항목 $questionCount개',
                    style: const TextStyle(
                      color: AdminColors.badgeText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              formatAdminDate(vote.createdAt),
              style: const TextStyle(
                color: AdminColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyVotes extends StatelessWidget {
  const _EmptyVotes();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: AdminMessage.success('아직 생성된 투표가 없습니다. 새 투표를 만들어주세요.'),
    );
  }
}
