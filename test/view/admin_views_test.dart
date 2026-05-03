import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taglow_admin/api/model/admin_user.dart';
import 'package:taglow_admin/api/service/admin_service_provider.dart';
import 'package:taglow_admin/api/service/mock_admin_service.dart';
import 'package:taglow_admin/api/service/question_image_upload_service.dart';
import 'package:taglow_admin/theme/admin_theme.dart';
import 'package:taglow_admin/view/auth/login_page.dart';
import 'package:taglow_admin/view/questions/question_editor_page.dart';
import 'package:taglow_admin/view/votes/vote_detail_page.dart';
import 'package:taglow_admin/view/votes/vote_list_page.dart';

void main() {
  testWidgets('login button stays disabled until credentials are entered', (
    tester,
  ) async {
    await _pumpAdminPage(tester, const LoginPage());

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '로그인'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('USER login renders an admin permission message', (tester) async {
    await _pumpAdminPage(
      tester,
      const LoginPage(),
      overrides: <Override>[
        adminServiceProvider.overrideWithValue(_UserOnlyAdminService()),
      ],
    );

    await tester.enterText(find.byType(TextField).at(0), 'user');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '로그인'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('관리자 권한이 필요합니다.'), findsOneWidget);
  });

  testWidgets('vote list renders vote cards and the create tile', (
    tester,
  ) async {
    await _pumpAdminPage(
      tester,
      const VoteListPage(),
      overrides: <Override>[
        adminServiceProvider.overrideWithValue(MockAdminService()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('투표 관리'), findsOneWidget);
    expect(find.text('Mock vote'), findsOneWidget);
    expect(find.text('세부 항목 1개'), findsOneWidget);
    expect(find.text('새로운 투표 만들기'), findsOneWidget);
  });

  testWidgets('vote detail renders the question grid and operation links', (
    tester,
  ) async {
    await _pumpAdminPage(
      tester,
      const VoteDetailPage(voteId: '1'),
      overrides: <Override>[
        adminServiceProvider.overrideWithValue(MockAdminService()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('세부 항목 관리'), findsOneWidget);
    expect(find.text('Mock question'), findsOneWidget);
    expect(find.text('항목 추가'), findsOneWidget);
    expect(find.text('플레이어 링크'), findsOneWidget);
    expect(
      find.textContaining('https://taglow-player.web.app'),
      findsOneWidget,
    );
  });

  testWidgets('question editor enables bottom buttons after image upload', (
    tester,
  ) async {
    await _pumpAdminPage(
      tester,
      const QuestionEditorPage(voteId: '1'),
      overrides: <Override>[
        adminServiceProvider.overrideWithValue(MockAdminService()),
        questionImageUploadServiceProvider.overrideWithValue(
          const MockQuestionImageUploadService(),
        ),
      ],
    );

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '완료하기'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField).first, '첫 항목');
    await tester.ensureVisible(find.text('이미지를 업로드하려면 탭하세요'));
    await tester.tap(find.text('이미지를 업로드하려면 탭하세요'));
    await tester.pumpAndSettle();

    expect(find.text('이미지가 준비되었습니다'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '완료하기'))
          .onPressed,
      isNotNull,
    );
  });
}

Future<void> _pumpAdminPage(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const <Override>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AdminTheme.data(), home: child),
    ),
  );
  await tester.pump();
}

class _UserOnlyAdminService extends MockAdminService {
  int logoutCount = 0;

  @override
  Future<AdminUser> login({
    required String name,
    required String password,
  }) async {
    return const AdminUser(id: '2', name: 'user', roles: {'USER'});
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
  }
}
