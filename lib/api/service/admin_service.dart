import '../model/admin_question.dart';
import '../model/admin_user.dart';
import '../model/admin_vote.dart';
import '../model/vote_status.dart';

abstract class AdminService {
  Future<AdminUser> signup({required String name, required String password});

  Future<AdminUser> login({required String name, required String password});

  Future<AdminUser?> fetchCurrentUser();

  Future<void> logout();

  Future<List<AdminVote>> fetchVotes();

  Future<AdminVote> createVote({required String name});

  Future<AdminVote> fetchVote(String voteId);

  Future<AdminVote> updateVote({
    required String voteId,
    String? name,
    VoteStatus? status,
  });

  Future<void> deleteVote(String voteId);

  Future<List<AdminQuestion>> fetchQuestions(String voteId);

  Future<AdminQuestion> createQuestion({
    required String voteId,
    required String title,
    required String detail,
    required String imageUrl,
    required double imageRatio,
  });

  Future<AdminQuestion> updateQuestion({
    required String questionId,
    String? title,
    String? detail,
    String? imageUrl,
    double? imageRatio,
  });

  Future<void> deleteQuestion(String questionId);

  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId);

  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId);
}
