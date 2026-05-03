import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/admin_url_builder.dart';
import '../model/admin_question.dart';
import '../model/admin_vote.dart';
import '../model/admin_vote_links.dart';
import '../service/admin_service.dart';
import '../service/admin_service_provider.dart';

final voteDetailControllerProvider = StateNotifierProvider.family<
  VoteDetailController,
  VoteDetailState,
  String
>((ref, voteId) {
  return VoteDetailController(
    service: ref.watch(adminServiceProvider),
    urlBuilder: ref.watch(adminUrlBuilderProvider),
    voteId: voteId,
  );
});

class VoteDetailState {
  const VoteDetailState({
    this.vote,
    this.questions = const <AdminQuestion>[],
    this.links,
    this.isLoading = false,
    this.errorMessage,
  });

  final AdminVote? vote;
  final List<AdminQuestion> questions;
  final AdminVoteLinks? links;
  final bool isLoading;
  final String? errorMessage;

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

class VoteDetailController extends StateNotifier<VoteDetailState> {
  VoteDetailController({
    required AdminService service,
    required AdminUrlBuilder urlBuilder,
    required String voteId,
  }) : _service = service,
       _urlBuilder = urlBuilder,
       _voteId = voteId,
       super(const VoteDetailState());

  final AdminService _service;
  final AdminUrlBuilder _urlBuilder;
  final String _voteId;

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

  String _message(Object error, {required String fallback}) {
    final text = error.toString();
    return text.isEmpty ? fallback : text;
  }
}
