import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/admin_url_builder.dart';
import '../model/admin_question.dart';
import '../model/admin_vote.dart';
import '../model/admin_vote_links.dart';
import '../service/admin_service.dart';
import '../service/admin_service_provider.dart';

/// vote 상세 화면 상태를 제공하는 family provider입니다.
/// View가 route의 voteId를 전달하면 Controller가 vote, questions, 운영 링크를 로드합니다.
/// URL 생성은 [AdminUrlBuilder]에 위임해 View가 participant/player 경로를 직접 만들지 않게 합니다.
final voteDetailControllerProvider =
    StateNotifierProvider.family<VoteDetailController, VoteDetailState, String>(
      (ref, voteId) {
        return VoteDetailController(
          service: ref.watch(adminServiceProvider),
          urlBuilder: ref.watch(adminUrlBuilderProvider),
          voteId: voteId,
        );
      },
    );

/// vote 상세 화면이 표시할 vote, question, link 상태입니다.
/// VoteDetailPage가 이 값을 구독해 상세, 항목 grid, participant/player link panel을 렌더링합니다.
/// fields:
/// - [vote]: 상세 대상 vote domain model입니다.
/// - [questions]: vote에 속한 question 목록입니다.
/// - [links]: voteId에서 생성한 participant QR/player 운영 링크 묶음입니다.
/// - [isLoading]: 상세 데이터 조회 진행 여부입니다.
/// - [errorMessage]: 상세 조회 실패를 View에 표시할 메시지입니다.
class VoteDetailState {
  /// vote 상세 상태를 생성합니다.
  /// Controller가 load 결과를 불변 값으로 교체하며 View에 전달합니다.
  /// Parameters:
  /// - [vote]: 상세 vote 정보입니다.
  /// - [questions]: vote에 속한 question 목록입니다.
  /// - [links]: 운영 링크 묶음입니다.
  /// - [isLoading]: 상세 로딩 여부입니다.
  /// - [errorMessage]: 오류 메시지입니다.
  /// Returns:
  /// - [instance]: vote 상세 상태를 보관하는 새 인스턴스입니다.
  const VoteDetailState({
    this.vote,
    this.questions = const <AdminQuestion>[],
    this.links,
    this.isLoading = false,
    this.errorMessage,
  });

  /// 상세 화면의 기준 vote입니다.
  /// top bar 제목과 운영 흐름의 저장 상태 판단에 사용됩니다.
  final AdminVote? vote;

  /// 상세 vote에 속한 question 목록입니다.
  /// grid View와 항목 수 표시가 이 값을 읽습니다.
  final List<AdminQuestion> questions;

  /// participant URL, QR payload, player URL을 담은 운영 링크입니다.
  /// [AdminUrlBuilder]가 생성하며 View는 그대로 표시합니다.
  final AdminVoteLinks? links;

  /// 상세 데이터 로딩 중인지 나타냅니다.
  /// RefreshIndicator와 로딩 spinner 표시의 기준입니다.
  final bool isLoading;

  /// 상세 조회 실패 메시지입니다.
  /// View는 service/gateway 세부 오류 대신 이 문구를 표시합니다.
  final String? errorMessage;

  /// 일부 vote 상세 상태만 교체한 새 상태를 만듭니다.
  /// load 성공, 로딩 종료, 오류 정리를 명시적으로 반영합니다.
  /// Parameters:
  /// - [vote]: 교체할 vote 정보입니다.
  /// - [questions]: 교체할 question 목록입니다.
  /// - [links]: 교체할 운영 링크 묶음입니다.
  /// - [isLoading]: 로딩 상태입니다.
  /// - [errorMessage]: 새 오류 메시지입니다.
  /// - [clearError]: 기존 오류 메시지를 지울지 결정합니다.
  /// Returns:
  /// - [result]: 변경값이 반영된 새 [VoteDetailState]입니다.
  VoteDetailState copyWith({
    AdminVote? vote,
    List<AdminQuestion>? questions,
    AdminVoteLinks? links,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VoteDetailState(
      vote: vote ?? this.vote,
      questions: questions ?? this.questions,
      links: links ?? this.links,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// vote 상세 조회와 운영 링크 생성을 조율하는 Controller입니다.
/// View 이벤트를 [AdminService] 조회와 [AdminUrlBuilder] 링크 생성으로 연결합니다.
/// participant QR payload는 링크 model에만 담겨 UI가 보안 정책을 재구성하지 않습니다.
/// fields:
/// - [_service]: vote와 question 조회를 수행하는 Service 계약입니다.
/// - [_urlBuilder]: participant/player URL 정책을 보유한 utility입니다.
/// - [_voteId]: 상세 조회와 링크 생성의 기준 vote 식별자입니다.
class VoteDetailController extends StateNotifier<VoteDetailState> {
  /// vote 상세 Controller를 생성합니다.
  /// family provider가 route voteId와 service/url builder를 주입합니다.
  /// Parameters:
  /// - [service]: vote와 question을 조회하는 관리자 Service입니다.
  /// - [urlBuilder]: 운영 링크를 생성하는 URL builder입니다.
  /// - [voteId]: 상세 대상 vote 식별자입니다.
  /// Returns:
  /// - [instance]: vote 상세 상태를 관리하는 새 Controller입니다.
  VoteDetailController({
    required AdminService service,
    required AdminUrlBuilder urlBuilder,
    required String voteId,
  }) : _service = service,
       _urlBuilder = urlBuilder,
       _voteId = voteId,
       super(const VoteDetailState());

  /// vote와 question을 조회하는 Service 의존성입니다.
  /// Controller가 gateway, mapper, endpoint를 직접 import하지 않게 합니다.
  final AdminService _service;

  /// participant URL과 player URL을 생성하는 utility 의존성입니다.
  /// route 문자열과 base URL 정책을 View 밖으로 모읍니다.
  final AdminUrlBuilder _urlBuilder;

  /// 현재 상세 화면의 vote 식별자입니다.
  /// Service 조회와 운영 링크 생성의 공통 입력입니다.
  final String _voteId;

  /// vote 상세 정보, question 목록, 운영 링크를 한 번에 로드합니다.
  /// API 조회는 Service가 담당하고 링크/QR payload는 local URL builder가 생성합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final vote = await _service.fetchVote(_voteId);
      final questions = await _service.fetchQuestions(_voteId);
      state = state.copyWith(
        vote: vote,
        questions: questions,
        links: _urlBuilder.buildVoteLinks(_voteId),
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, fallback: '투표 상세를 불러오지 못했습니다.'),
      );
    }
  }

  /// 상세 조회 오류를 사용자 표시 메시지로 정규화합니다.
  /// 빈 오류 문자열이면 호출자가 지정한 fallback 문구를 사용합니다.
  /// Parameters:
  /// - [error]: Service 조회 중 발생한 오류 객체입니다.
  /// - [fallback]: 오류 문자열이 비어 있을 때 사용할 기본 메시지입니다.
  /// Returns:
  /// - [result]: 사용자에게 표시할 오류 메시지입니다.
  String _message(Object error, {required String fallback}) {
    final text = error.toString();
    return text.isEmpty ? fallback : text;
  }
}
