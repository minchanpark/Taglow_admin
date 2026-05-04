import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api/controller/auth_controller.dart';
import 'theme/admin_theme.dart';
import 'view/auth/login_page.dart';
import 'view/auth/signup_page.dart';
import 'view/questions/question_editor_page.dart';
import 'view/votes/vote_create_page.dart';
import 'view/votes/vote_detail_page.dart';
import 'view/votes/vote_list_page.dart';

/// 관리자 앱의 route graph와 auth redirect 정책을 제공하는 provider입니다.
/// [AuthController] 상태를 읽어 인증되지 않았거나 콘솔 접근 role이 없는 사용자를 로그인 화면으로 돌려보냅니다.
/// View는 route parameter만 받고 API endpoint나 Service wiring을 알지 않습니다.
final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/signup';

      if (path == '/') {
        return authState.canManage ? '/votes' : '/login';
      }
      if (!authState.canManage && !isAuthRoute) {
        return '/login';
      }
      if (authState.canManage && isAuthRoute) {
        return '/votes';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
      GoRoute(path: '/votes', builder: (_, _) => const VoteListPage()),
      GoRoute(path: '/votes/new', builder: (_, _) => const VoteCreatePage()),
      GoRoute(
        path: '/votes/:voteId',
        builder: (_, state) {
          return VoteDetailPage(voteId: state.pathParameters['voteId'] ?? '');
        },
      ),
      GoRoute(
        path: '/votes/:voteId/questions/new',
        builder: (_, state) {
          return QuestionEditorPage(
            voteId: state.pathParameters['voteId'] ?? '',
          );
        },
      ),
    ],
  );
});

/// Taglow admin 앱의 최상위 widget입니다.
/// router, theme, 초기 세션 확인을 연결하고 실제 기능은 하위 View/Controller layer에 위임합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class TaglowAdminApp extends ConsumerStatefulWidget {
  /// 최상위 app widget을 생성합니다.
  /// [ProviderScope] 아래에서 사용되어 Riverpod provider를 읽을 수 있습니다.
  /// Parameters:
  /// - [key]: Flutter widget 식별 key입니다.
  /// Returns:
  /// - [instance]: Taglow admin app widget 인스턴스입니다.
  const TaglowAdminApp({super.key});

  /// 앱 state 객체를 생성합니다.
  /// 초기 세션 확인과 router build는 [_TaglowAdminAppState]가 담당합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [result]: app lifecycle을 관리할 state 객체입니다.
  @override
  ConsumerState<TaglowAdminApp> createState() => _TaglowAdminAppState();
}

/// 앱 시작 lifecycle과 Material router 구성을 관리하는 state입니다.
/// initState에서 auth session을 확인하고 build에서 router/theme provider를 연결합니다.
/// fields:
/// - [none]: 저장 필드가 없으며, 연결 관계는 생성/호출 위치에서 결정됩니다.
class _TaglowAdminAppState extends ConsumerState<TaglowAdminApp> {
  /// 앱 state 초기화 시 기존 auth session 확인을 예약합니다.
  /// microtask로 Controller 호출을 넘겨 widget 초기화와 provider read 순서를 안전하게 유지합니다.
  /// Parameters:
  /// - [none]: 이 동작은 외부 입력 없이 현재 객체나 주입된 의존성을 사용합니다.
  /// Returns:
  /// - [void]: 상태 변경이나 부수 효과만 수행하고 값을 반환하지 않습니다.
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(authControllerProvider.notifier).checkSession(),
    );
  }

  /// MaterialApp.router를 구성해 theme와 GoRouter를 연결합니다.
  /// route redirect는 [adminRouterProvider]가 AuthState를 기준으로 처리합니다.
  /// Parameters:
  /// - [context]: Flutter build context입니다.
  /// Returns:
  /// - [result]: 관리자 앱의 root widget tree입니다.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Taglow Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.data(),
      routerConfig: ref.watch(adminRouterProvider),
    );
  }
}
