import 'package:flutter_test/flutter_test.dart';
import 'package:taglow_admin/api/controller/auth_controller.dart';
import 'package:taglow_admin/api/controller/question_editor_controller.dart';
import 'package:taglow_admin/api/controller/vote_detail_controller.dart';
import 'package:taglow_admin/api/controller/vote_list_controller.dart';
import 'package:taglow_admin/api/model/admin_question.dart';
import 'package:taglow_admin/api/model/admin_user.dart';
import 'package:taglow_admin/api/model/admin_vote.dart';
import 'package:taglow_admin/api/model/vote_status.dart';
import 'package:taglow_admin/api/service/admin_service.dart';
import 'package:taglow_admin/api/service/mock_admin_service.dart';
import 'package:taglow_admin/api/service/question_image_upload_service.dart';
import 'package:taglow_admin/utils/admin_url_builder.dart';

void main() {
  group('AuthController', () {
    test('allows ADMIN login', () async {
      final controller = AuthController(
        _FakeAdminService(
          loginUser: const AdminUser(id: '1', name: 'admin', roles: {'ADMIN'}),
        ),
      );

      final success = await controller.login(
        name: 'admin',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(controller.state.canManage, isTrue);
      expect(controller.state.errorMessage, isNull);
    });

    test('blocks USER login and logs out the server session', () async {
      final service = _FakeAdminService(
        loginUser: const AdminUser(id: '2', name: 'user', roles: {'USER'}),
      );
      final controller = AuthController(service);

      final success = await controller.login(
        name: 'user',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(service.logoutCount, 1);
      expect(controller.state.user, isNull);
      expect(controller.state.errorMessage, '관리자 권한이 필요합니다.');
    });

    test(
      'keeps signup users as non-admin and shows completion message',
      () async {
        final service = _FakeAdminService(
          signupUser: const AdminUser(
            id: '3',
            name: 'new-user',
            roles: {'USER'},
          ),
        );
        final controller = AuthController(service);

        final success = await controller.signup(
          name: 'new-user',
          password: 'password123',
          passwordConfirm: 'password123',
        );

        expect(success, isTrue);
        expect(service.signupNames, <String>['new-user']);
        expect(controller.state.user, isNull);
        expect(
          controller.state.successMessage,
          '회원가입이 완료되었습니다. 최고 관리자 승인 후 관리자 기능을 사용할 수 있습니다.',
        );
      },
    );
  });

  group('VoteListController', () {
    test('loads votes with question counts and creates a new vote', () async {
      final service = MockAdminService();
      final controller = VoteListController(service);

      await controller.loadVotes();

      expect(controller.state.votes.single.name, 'Mock vote');
      expect(controller.state.questionCounts['1'], 1);

      final vote = await controller.createVote('새 투표');

      expect(vote, isNotNull);
      expect(controller.state.votes.first.name, '새 투표');
      expect(controller.state.questionCounts[vote!.id], 0);
    });
  });

  group('VoteDetailController', () {
    test('loads vote, questions, and participant/player links', () async {
      final controller = VoteDetailController(
        service: MockAdminService(),
        urlBuilder: const AdminUrlBuilder(
          participantBaseUrl: 'https://participant.test/',
          playerBaseUrl: 'https://player.test/',
        ),
        voteId: '1',
      );

      await controller.load();

      expect(controller.state.vote?.name, 'Mock vote');
      expect(controller.state.questions.single.title, 'Mock question');
      expect(
        controller.state.links?.participantUrl,
        'https://participant.test/e/1',
      );
      expect(
        controller.state.links?.playerUrl,
        'https://player.test/display/1',
      );
    });
  });

  group('QuestionEditorController', () {
    test('validates required fields before saving', () async {
      final controller = QuestionEditorController(
        voteId: '1',
        service: MockAdminService(),
        uploadService: const MockQuestionImageUploadService(),
      );

      final saved = await controller.save(resetAfterSave: false);

      expect(saved, isNull);
      expect(controller.state.errorMessage, '항목 제목을 입력해주세요.');
    });

    test('uploads image and saves a question', () async {
      final controller = QuestionEditorController(
        voteId: '1',
        service: MockAdminService(),
        uploadService: const MockQuestionImageUploadService(),
      );

      controller.updateTitle('첫 항목');
      controller.updateDetail('상세 설명');
      await controller.uploadImage();
      final saved = await controller.save(resetAfterSave: false);

      expect(saved?.title, '첫 항목');
      expect(saved?.imageUrl, startsWith('https://cdn.taglow.local/'));
      expect(controller.state.savedQuestion?.id, saved?.id);
      expect(controller.state.successMessage, '항목이 저장되었습니다.');
    });

    test('can reset the draft after saving the next item', () async {
      final controller = QuestionEditorController(
        voteId: '1',
        service: MockAdminService(),
        uploadService: const MockQuestionImageUploadService(),
      );

      controller.updateTitle('반복 항목');
      await controller.uploadImage();
      final saved = await controller.save(resetAfterSave: true);

      expect(saved, isNotNull);
      expect(controller.state.title, isEmpty);
      expect(controller.state.image, isNull);
      expect(controller.state.successMessage, '항목이 저장되었습니다.');
    });
  });
}

class _FakeAdminService implements AdminService {
  _FakeAdminService({
    this.loginUser = const AdminUser(id: '1', name: 'admin', roles: {'ADMIN'}),
    this.signupUser = const AdminUser(id: '2', name: 'user', roles: {'USER'}),
  });

  final AdminUser loginUser;
  final AdminUser signupUser;
  final List<String> signupNames = <String>[];
  int logoutCount = 0;

  @override
  Future<AdminUser> login({
    required String name,
    required String password,
  }) async {
    return loginUser;
  }

  @override
  Future<AdminUser> signup({
    required String name,
    required String password,
  }) async {
    signupNames.add(name);
    return signupUser;
  }

  @override
  Future<AdminUser?> fetchCurrentUser() async => null;

  @override
  Future<void> logout() async {
    logoutCount += 1;
  }

  @override
  Future<List<AdminVote>> fetchVotes() => throw UnimplementedError();

  @override
  Future<AdminVote> createVote({required String name}) =>
      throw UnimplementedError();

  @override
  Future<AdminVote> fetchVote(String voteId) => throw UnimplementedError();

  @override
  Future<AdminVote> updateVote({
    required String voteId,
    String? name,
    VoteStatus? status,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteVote(String voteId) => throw UnimplementedError();

  @override
  Future<List<AdminQuestion>> fetchQuestions(String voteId) =>
      throw UnimplementedError();

  @override
  Future<AdminQuestion> createQuestion({
    required String voteId,
    required String title,
    required String detail,
    required String imageUrl,
    required double imageRatio,
  }) => throw UnimplementedError();

  @override
  Future<AdminQuestion> updateQuestion({
    required String questionId,
    String? title,
    String? detail,
    String? imageUrl,
    double? imageRatio,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteQuestion(String questionId) => throw UnimplementedError();

  @override
  Future<Map<String, Object?>> fetchPublicVoteDisplay(String voteId) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> fetchPublicQuestions(String voteId) =>
      throw UnimplementedError();
}
