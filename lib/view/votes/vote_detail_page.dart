import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/controller/vote_detail_controller.dart';
import '../../api/model/admin_question.dart';
import '../../api/model/admin_vote_links.dart';
import '../../theme/admin_theme.dart';
import '../admin_widgets.dart';
import 'widgets/participant_share_sheet.dart';

/// 단일 vote의 question 목록과 운영 링크를 보여주는 상세 화면입니다.
/// [VoteDetailController]가 vote/question/API 조회와 URL builder 결과를 상태로 제공합니다.
/// fields:
/// - [voteId]: 상세로 표시할 vote 식별자입니다.
class VoteDetailPage extends ConsumerStatefulWidget {
  /// vote 상세 화면 widget을 생성합니다.
  /// route parameter의 voteId를 Controller family provider에 전달합니다.
  /// Parameters:
  /// - [voteId]: 상세 대상 vote 식별자입니다.
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: vote 상세 화면 widget 인스턴스입니다.
  const VoteDetailPage({required this.voteId, super.key});

  /// 상세로 표시할 vote 식별자입니다.
  /// 데이터 조회, 새 question route, 운영 링크 생성 기준으로 쓰입니다.
  final String voteId;

  /// vote 상세 화면 state를 생성합니다.
  /// 초기 load와 refresh action을 state에서 Controller로 연결합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: vote 상세 화면 state 객체입니다.
  @override
  ConsumerState<VoteDetailPage> createState() => _VoteDetailPageState();
}

/// vote 상세 화면의 lifecycle과 렌더링을 관리하는 state입니다.
/// View는 Controller 상태를 읽고 question grid와 participant/player link panel을 표시합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class _VoteDetailPageState extends ConsumerState<VoteDetailPage> {
  /// 화면 진입 시 vote 상세 데이터를 비동기로 로드합니다.
  /// microtask로 provider notifier 호출을 예약해 build 전 lifecycle을 안전하게 유지합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () =>
          ref.read(voteDetailControllerProvider(widget.voteId).notifier).load(),
    );
  }

  /// vote 상세 화면 UI를 빌드합니다.
  /// 로딩, 오류, question grid, participant/player link panel을 Controller 상태에 맞춰 렌더링합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: vote 상세 화면 widget tree입니다.
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voteDetailControllerProvider(widget.voteId));
    final voteName = state.vote?.name ?? '투표 상세';
    final links = state.links;

    return AdminMobileShell(
      child: Column(
        children: <Widget>[
          AdminTopBar(
            title: voteName,
            onBack: () => context.go('/votes'),
            trailing: IconButton(
              tooltip: '공유',
              onPressed: links == null
                  ? null
                  : () => _showParticipantShareSheet(context, links),
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
                  if (links != null) ...<Widget>[
                    const SizedBox(height: 28),
                    _LinkPanel(label: '참여자 링크', value: links.participantUrl),
                    const SizedBox(height: 12),
                    _LinkPanel(label: '플레이어 링크', value: links.playerUrl),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 참여자 QR과 링크를 공유하는 modal sheet를 엽니다.
  /// 실제 공유/복사 동작은 Controller action으로 위임하고 결과는 SnackBar로 표시합니다.
  /// Parameters:
  /// - [context]: 현재 화면 context입니다.
  /// - [links]: 공유 sheet에 표시할 운영 링크 model입니다.
  /// Returns:
  /// - [completion]: modal sheet가 닫힐 때 완료됩니다.
  Future<void> _showParticipantShareSheet(
    BuildContext context,
    AdminVoteLinks links,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ParticipantShareSheet(
          links: links,
          onExternalShare: () => _runShareSheetAction(
            sheetContext,
            () => ref
                .read(voteDetailControllerProvider(widget.voteId).notifier)
                .shareParticipantLink(),
          ),
          onCopyLink: () => _runShareSheetAction(
            sheetContext,
            () => ref
                .read(voteDetailControllerProvider(widget.voteId).notifier)
                .copyParticipantLink(),
          ),
        );
      },
    );
  }

  /// 공유 sheet action을 실행하고 sheet 닫기와 feedback 표시를 처리합니다.
  /// Parameters:
  /// - [sheetContext]: modal sheet 내부 context입니다.
  /// - [action]: Controller가 제공하는 공유/복사 action입니다.
  /// Returns:
  /// - [completion]: action과 feedback 처리 완료를 의미합니다.
  Future<void> _runShareSheetAction(
    BuildContext sheetContext,
    Future<String> Function() action,
  ) async {
    final message = await action();
    if (sheetContext.mounted) {
      Navigator.of(sheetContext).maybePop();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// vote 상세의 question tile grid를 렌더링하는 private widget입니다.
/// 마지막 tile은 새 question 추가 action으로 고정됩니다.
/// fields:
/// - [questions]: grid에 표시할 question 목록입니다.
/// - [onAdd]: 새 question 추가 tile tap callback입니다.
class _QuestionGrid extends StatelessWidget {
  /// question grid widget을 생성합니다.
  /// View state가 전달한 question 목록과 add callback을 그대로 렌더링합니다.
  /// Parameters:
  /// - [questions]: 표시할 question 목록입니다.
  /// - [onAdd]: 새 question 추가 callback입니다.
  /// Returns:
  /// - [instance]: question grid widget 인스턴스입니다.
  const _QuestionGrid({required this.questions, required this.onAdd});

  /// grid에 표시할 question domain model 목록입니다.
  /// 각 항목은 [_QuestionTile]로 렌더링됩니다.
  final List<AdminQuestion> questions;

  /// 새 question 추가 tile의 tap callback입니다.
  /// VoteDetailPage가 question editor route 이동을 연결합니다.
  final VoidCallback onAdd;

  /// question tile들과 add tile을 2열 grid로 빌드합니다.
  /// parent ListView 안에서 동작하도록 shrinkWrap과 non-scroll physics를 사용합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: question grid widget tree입니다.
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

/// 단일 question을 카드 형태로 표시하는 private widget입니다.
/// 현재 MVP에서는 question 제목과 placeholder 참여 수를 보여줍니다.
/// fields:
/// - [question]: 표시할 question domain model입니다.
class _QuestionTile extends StatelessWidget {
  /// question tile widget을 생성합니다.
  /// VoteDetailPage의 grid가 question 목록을 tile로 변환할 때 사용합니다.
  /// Parameters:
  /// - [question]: 표시할 question입니다.
  /// Returns:
  /// - [instance]: question tile widget 인스턴스입니다.
  const _QuestionTile({required this.question});

  /// 카드에 표시할 question domain model입니다.
  /// title은 ellipsis 처리되어 compact grid 안에서 안전하게 보입니다.
  final AdminQuestion question;

  /// question 카드 UI를 빌드합니다.
  /// 질문 수나 참여자 통계가 추가되면 이 View helper가 표시만 담당합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: question tile widget tree입니다.
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

/// participant/player URL 값을 표시하는 private link panel입니다.
/// URL 생성은 Controller/utility가 담당하고 이 widget은 selectable text만 제공합니다.
/// fields:
/// - [label]: 링크 종류를 표시하는 label입니다.
/// - [value]: 운영자가 확인하거나 복사할 URL 값입니다.
class _LinkPanel extends StatelessWidget {
  /// link panel widget을 생성합니다.
  /// VoteDetailPage가 participant URL과 player URL 각각에 사용합니다.
  /// Parameters:
  /// - [label]: panel label입니다.
  /// - [value]: 표시할 URL 값입니다.
  /// Returns:
  /// - [instance]: link panel widget 인스턴스입니다.
  const _LinkPanel({required this.label, required this.value});

  /// link panel 상단에 표시할 label입니다.
  /// participant/player 종류를 운영자가 빠르게 구분하게 합니다.
  final String label;

  /// 표시할 URL 문자열입니다.
  /// participant QR payload나 player URL은 Controller state의 링크 model에서 옵니다.
  final String value;

  /// label과 selectable URL text를 가진 panel을 빌드합니다.
  /// 복사 service가 연결되기 전에도 운영자가 URL을 직접 선택할 수 있습니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: link panel widget tree입니다.
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
