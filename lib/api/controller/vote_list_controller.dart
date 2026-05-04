import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/admin_vote.dart';
import '../service/admin_service.dart';
import '../service/admin_service_provider.dart';

/// vote 목록 상태를 제공하는 Riverpod provider입니다.
/// Vote list/create View가 같은 Controller를 통해 목록 조회와 생성 action을 수행합니다.
/// 실제 API와 mock 구현 교체는 [AdminService] provider 뒤에서 처리됩니다.
final voteListControllerProvider =
    StateNotifierProvider<VoteListController, VoteListState>((ref) {
      return VoteListController(ref.watch(adminServiceProvider));
    });

/// vote 목록 화면과 vote 생성 화면이 공유하는 UI 상태입니다.
/// View는 이 상태를 읽어 목록, 비어 있음, 로딩, 제출, 오류 표시를 결정합니다.
/// fields:
/// - [votes]: 현재 로드된 vote 목록입니다.
/// - [questionCounts]: voteId별 question 개수 캐시입니다.
/// - [isLoading]: 목록 조회 진행 여부입니다.
/// - [isSubmitting]: vote 생성 요청 진행 여부입니다.
/// - [errorMessage]: 목록 조회나 생성 실패를 View에 표시할 메시지입니다.
class VoteListState {
  /// vote 목록 상태를 생성합니다.
  /// Controller가 목록 조회와 생성 결과를 불변 값으로 교체합니다.
  /// Parameters:
  /// - [votes]: vote 목록입니다.
  /// - [questionCounts]: voteId별 question 개수입니다.
  /// - [isLoading]: 목록 로딩 여부입니다.
  /// - [isSubmitting]: 생성 제출 로딩 여부입니다.
  /// - [errorMessage]: 오류 메시지입니다.
  /// Returns:
  /// - [instance]: vote 목록 상태를 보관하는 새 인스턴스입니다.
  const VoteListState({
    this.votes = const <AdminVote>[],
    this.questionCounts = const <String, int>{},
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// 현재 목록에 표시할 vote들입니다.
  /// VoteListPage가 카드 목록과 카운트 summary를 만들 때 사용합니다.
  final List<AdminVote> votes;

  /// voteId별 question 개수입니다.
  /// 목록 카드가 상세 조회 없이 항목 개수를 표시하도록 Controller가 채웁니다.
  final Map<String, int> questionCounts;

  /// vote 목록을 불러오는 중인지 나타냅니다.
  /// View의 RefreshIndicator와 spinner 표시 기준입니다.
  final bool isLoading;

  /// 새 vote 생성 요청이 진행 중인지 나타냅니다.
  /// VoteCreatePage의 하단 버튼 busy/disabled 상태와 연결됩니다.
  final bool isSubmitting;

  /// 목록 조회 또는 생성 실패 메시지입니다.
  /// View는 이 값을 통해 서비스 오류를 운영자에게 표시합니다.
  final String? errorMessage;

  /// 표시할 vote가 없는지 계산합니다.
  /// VoteListPage가 empty state를 선택할 때 사용합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: vote 목록이 비어 있는지 여부입니다.
  bool get isEmpty => votes.isEmpty;

  /// 일부 목록 상태만 교체한 새 [VoteListState]를 만듭니다.
  /// Controller가 로딩, 생성 결과, 오류 정리를 명시적으로 반영할 때 사용합니다.
  /// Parameters:
  /// - [votes]: 교체할 vote 목록입니다.
  /// - [questionCounts]: 교체할 question 개수 map입니다.
  /// - [isLoading]: 목록 로딩 상태입니다.
  /// - [isSubmitting]: 생성 제출 상태입니다.
  /// - [errorMessage]: 새 오류 메시지입니다.
  /// - [clearError]: 기존 오류 메시지를 지울지 결정합니다.
  /// Returns:
  /// - [result]: 변경값이 반영된 새 [VoteListState]입니다.
  VoteListState copyWith({
    List<AdminVote>? votes,
    Map<String, int>? questionCounts,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VoteListState(
      votes: votes ?? this.votes,
      questionCounts: questionCounts ?? this.questionCounts,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

/// vote 목록 조회와 새 vote 생성을 조율하는 Controller입니다.
/// View 이벤트를 [AdminService] 호출로 연결하고 question 개수도 목록 상태에 합칩니다.
/// endpoint나 payload 세부 값은 Service/Gateway/Mapper 계층에 남겨둡니다.
/// fields:
/// - [_service]: vote와 question 조회 및 vote 생성을 수행하는 Service 계약입니다.
class VoteListController extends StateNotifier<VoteListState> {
  /// vote 목록 Controller를 생성합니다.
  /// provider가 현재 설정에 맞는 [AdminService] 구현을 주입합니다.
  /// Parameters:
  /// - [_service]: vote 목록과 생성 API를 수행하는 service 계약입니다.
  /// Returns:
  /// - [instance]: vote 목록 상태를 관리하는 새 Controller입니다.
  VoteListController(this._service) : super(const VoteListState());

  /// vote 목록, question 개수, vote 생성을 수행하는 Service 의존성입니다.
  /// Controller가 concrete gateway나 mock 구현을 알지 않게 합니다.
  final AdminService _service;

  /// vote 목록과 각 vote의 question 개수를 로드합니다.
  /// question 개수 조회 실패는 해당 vote를 0개로 표시해 목록 전체 실패로 번지지 않게 합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [completion]: 비동기 작업 완료를 의미하며 값은 반환하지 않습니다.
  Future<void> loadVotes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final votes = await _service.fetchVotes();
      final counts = <String, int>{};
      for (final vote in votes) {
        try {
          counts[vote.id] = (await _service.fetchQuestions(vote.id)).length;
        } catch (_) {
          counts[vote.id] = 0;
        }
      }
      state = state.copyWith(
        votes: votes,
        questionCounts: counts,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error, fallback: '투표 목록을 불러오지 못했습니다.'),
      );
    }
  }

  /// 새 vote를 생성하고 목록 맨 앞에 반영합니다.
  /// 입력 validation은 Controller에서 처리하고 실제 저장은 [AdminService]에 위임합니다.
  /// Parameters:
  /// - [name]: VoteCreatePage에서 입력한 vote 이름입니다.
  /// Returns:
  /// - [result]: 생성된 [AdminVote]이거나 실패 시 null입니다.
  Future<AdminVote?> createVote(String name) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: '투표 제목을 입력해주세요.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final vote = await _service.createVote(name: name.trim());
      state = state.copyWith(
        votes: <AdminVote>[vote, ...state.votes],
        questionCounts: <String, int>{vote.id: 0, ...state.questionCounts},
        isSubmitting: false,
      );
      return vote;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _message(error, fallback: '투표를 만들지 못했습니다.'),
      );
      return null;
    }
  }

  /// 목록 조회나 생성 오류를 사용자 표시 메시지로 정규화합니다.
  /// 빈 오류 문자열이면 호출자가 지정한 fallback 문구를 사용합니다.
  /// Parameters:
  /// - [error]: Service 호출 중 발생한 오류 객체입니다.
  /// - [fallback]: 오류 문자열이 비어 있을 때 사용할 기본 메시지입니다.
  /// Returns:
  /// - [result]: 사용자에게 표시할 오류 메시지입니다.
  String _message(Object error, {required String fallback}) {
    final text = error.toString();
    return text.isEmpty ? fallback : text;
  }
}
