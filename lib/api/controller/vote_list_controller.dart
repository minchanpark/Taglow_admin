import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/admin_vote.dart';
import '../service/admin_service.dart';
import '../service/admin_service_provider.dart';

final voteListControllerProvider =
    StateNotifierProvider<VoteListController, VoteListState>((ref) {
      return VoteListController(ref.watch(adminServiceProvider));
    });

class VoteListState {
  const VoteListState({
    this.votes = const <AdminVote>[],
    this.questionCounts = const <String, int>{},
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<AdminVote> votes;
  final Map<String, int> questionCounts;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isEmpty => votes.isEmpty;

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

class VoteListController extends StateNotifier<VoteListState> {
  VoteListController(this._service) : super(const VoteListState());

  final AdminService _service;

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

  String _message(Object error, {required String fallback}) {
    final text = error.toString();
    return text.isEmpty ? fallback : text;
  }
}
