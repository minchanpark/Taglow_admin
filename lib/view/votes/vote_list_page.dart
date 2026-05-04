import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/vote_list_controller.dart';
import '../../api/model/admin_vote.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';

/// 관리자 vote 목록 화면입니다.
/// [VoteListController]가 vote 목록과 question count를 로드하고 View는 카드 목록을 렌더링합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class VoteListPage extends ConsumerStatefulWidget {
  /// vote 목록 화면 widget을 생성합니다.
  /// router가 인증된 운영자를 `/votes`로 보낼 때 렌더링됩니다.
  /// Parameters:
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: vote 목록 화면 widget 인스턴스입니다.
  const VoteListPage({super.key});

  /// vote 목록 화면 state를 생성합니다.
  /// 초기 load와 pull-to-refresh action을 state에서 Controller로 연결합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: vote 목록 화면 state 객체입니다.
  @override
  ConsumerState<VoteListPage> createState() => _VoteListPageState();
}

/// vote 목록 화면 lifecycle과 렌더링을 관리하는 state입니다.
/// View는 [VoteListState]를 읽고 loading/error/empty/list 상태를 분기합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class _VoteListPageState extends ConsumerState<VoteListPage> {
  /// 화면 진입 시 vote 목록을 비동기로 로드합니다.
  /// microtask로 provider notifier 호출을 예약해 초기 widget lifecycle과 분리합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(voteListControllerProvider.notifier).loadVotes(),
    );
  }

  /// vote 목록 화면 UI를 빌드합니다.
  /// 목록 refresh, empty state, vote card tap navigation을 Controller state와 연결합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: vote 목록 화면 widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voteListControllerProvider);

    return AdminMobileShell(
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
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
                Container(
                  height: 30,
                  color: AdminColors.surface,
                  child: Image.asset("assets/logo/taglow_logo.png"),
                ),
                SizedBox(height: 10),
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

/// vote 목록의 단일 vote card를 렌더링하는 private widget입니다.
/// 카드 tap은 상세 route 이동으로 연결되고 question count와 생성일을 함께 표시합니다.
/// fields:
/// - [vote]: 표시할 vote domain model입니다.
/// - [questionCount]: 해당 vote에 속한 question 개수입니다.
/// - [onTap]: 카드 tap callback입니다.
class _VoteCard extends StatelessWidget {
  /// vote card widget을 생성합니다.
  /// VoteListPage가 목록 상태를 카드 목록으로 변환할 때 사용합니다.
  /// Parameters:
  /// - [vote]: 표시할 vote입니다.
  /// - [questionCount]: 표시할 question 개수입니다.
  /// - [onTap]: 카드 tap callback입니다.
  /// Returns:
  /// - [instance]: vote card widget 인스턴스입니다.
  const _VoteCard({
    required this.vote,
    required this.questionCount,
    required this.onTap,
  });

  /// 카드에 표시할 vote domain model입니다.
  /// 이름과 생성일 표시의 source입니다.
  final AdminVote vote;

  /// 카드 badge에 표시할 question 개수입니다.
  /// [VoteListController]가 vote별 question 조회로 채운 값입니다.
  final int questionCount;

  /// 카드 tap 시 실행할 callback입니다.
  /// VoteListPage가 `/votes/{voteId}` route 이동을 연결합니다.
  final VoidCallback onTap;

  /// vote card UI를 빌드합니다.
  /// 긴 vote 이름은 ellipsis 처리하고 생성일은 [formatAdminDate]로 표시합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: vote card widget tree입니다.
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

/// vote가 하나도 없을 때 표시하는 empty state widget입니다.
/// 새 vote 생성 action은 목록 하단 [AddTile]이 담당하고 이 widget은 안내 메시지만 제공합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class _EmptyVotes extends StatelessWidget {
  /// empty state widget을 생성합니다.
  /// VoteListPage가 목록이 비어 있을 때 렌더링합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [instance]: empty state widget 인스턴스입니다.
  const _EmptyVotes();

  /// vote 없음 안내 메시지를 빌드합니다.
  /// 운영자가 다음 action을 이해하도록 새 vote 생성 안내를 표시합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: empty state widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: AdminMessage.success('아직 생성된 투표가 없습니다. 새 투표를 만들어주세요.'),
    );
  }
}
