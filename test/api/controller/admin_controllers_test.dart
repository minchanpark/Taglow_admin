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
import 'package:taglow_admin/api/service/participant_share_service.dart';
import 'package:taglow_admin/api/service/question_image_picker_service.dart';
import 'package:taglow_admin/api/service/question_image_upload_service.dart';
import 'package:taglow_admin/utils/admin_url_builder.dart';
import 'package:taglow_admin/utils/clipboard_helper.dart';

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

    test('allows USER login', () async {
      final service = _FakeAdminService(
        loginUser: const AdminUser(id: '2', name: 'user', roles: {'USER'}),
      );
      final controller = AuthController(service);

      final success = await controller.login(
        name: 'user',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(service.logoutCount, 0);
      expect(controller.state.user?.name, 'user');
      expect(controller.state.canManage, isTrue);
      expect(controller.state.errorMessage, isNull);
    });

    test('blocks unsupported roles', () async {
      final service = _FakeAdminService(
        loginUser: const AdminUser(id: '3', name: 'guest', roles: {}),
      );
      final controller = AuthController(service);

      final success = await controller.login(
        name: 'guest',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(service.logoutCount, 0);
      expect(controller.state.user, isNull);
      expect(controller.state.errorMessage, '운영 콘솔 접근 권한이 없습니다.');
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
          '회원가입이 완료되었습니다. 로그인 후 운영 콘솔을 사용할 수 있습니다.',
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
        clipboardHelper: _RecordingClipboardHelper(),
        participantShareService: _RecordingParticipantShareService(),
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

    test('copies the participant link through the clipboard helper', () async {
      final clipboard = _RecordingClipboardHelper();
      final controller = VoteDetailController(
        service: MockAdminService(),
        urlBuilder: const AdminUrlBuilder(
          participantBaseUrl: 'https://participant.test/',
          playerBaseUrl: 'https://player.test/',
        ),
        clipboardHelper: clipboard,
        participantShareService: _RecordingParticipantShareService(),
        voteId: '1',
      );

      await controller.load();
      final message = await controller.copyParticipantLink();

      expect(message, '참여자 링크를 복사했습니다.');
      expect(clipboard.copiedText, 'https://participant.test/e/1');
    });

    test('shares the participant link through the share service', () async {
      final shareService = _RecordingParticipantShareService();
      final controller = VoteDetailController(
        service: MockAdminService(),
        urlBuilder: const AdminUrlBuilder(
          participantBaseUrl: 'https://participant.test/',
          playerBaseUrl: 'https://player.test/',
        ),
        clipboardHelper: _RecordingClipboardHelper(),
        participantShareService: shareService,
        voteId: '1',
      );

      await controller.load();
      final message = await controller.shareParticipantLink();

      expect(message, '외부 공유 화면을 열었습니다.');
      expect(shareService.title, 'Mock vote 참여 링크');
      expect(shareService.text, 'Taglow 참여 링크입니다.');
      expect(shareService.url, 'https://participant.test/e/1');
    });

    test(
      'copies the participant link when external sharing is unavailable',
      () async {
        final clipboard = _RecordingClipboardHelper();
        final controller = VoteDetailController(
          service: MockAdminService(),
          urlBuilder: const AdminUrlBuilder(
            participantBaseUrl: 'https://participant.test/',
            playerBaseUrl: 'https://player.test/',
          ),
          clipboardHelper: clipboard,
          participantShareService: _RecordingParticipantShareService(
            exception: const ParticipantShareException('공유 미지원'),
          ),
          voteId: '1',
        );

        await controller.load();
        final message = await controller.shareParticipantLink();

        expect(message, '외부 공유를 지원하지 않아 링크를 복사했습니다.');
        expect(clipboard.copiedText, 'https://participant.test/e/1');
      },
    );
  });

  group('QuestionEditorController', () {
    test('validates required fields before saving', () async {
      final controller = QuestionEditorController(
        voteId: '1',
        service: MockAdminService(),
        imagePicker: const MockQuestionImagePickerService(),
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
        imagePicker: const MockQuestionImagePickerService(),
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
        imagePicker: const MockQuestionImagePickerService(),
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

class _RecordingClipboardHelper implements ClipboardHelper {
  String? copiedText;

  @override
  Future<void> copyText(String value) async {
    copiedText = value;
  }
}

class _RecordingParticipantShareService implements ParticipantShareService {
  _RecordingParticipantShareService({this.exception});

  final ParticipantShareException? exception;
  String? title;
  String? text;
  String? url;

  @override
  Future<void> shareParticipantLink({
    required String title,
    required String text,
    required String url,
  }) async {
    final exception = this.exception;
    if (exception != null) {
      throw exception;
    }
    this.title = title;
    this.text = text;
    this.url = url;
  }
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
