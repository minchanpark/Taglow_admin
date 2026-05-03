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

class TaglowAdminApp extends ConsumerStatefulWidget {
  const TaglowAdminApp({super.key});

  @override
  ConsumerState<TaglowAdminApp> createState() => _TaglowAdminAppState();
}

class _TaglowAdminAppState extends ConsumerState<TaglowAdminApp> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(authControllerProvider.notifier).checkSession(),
    );
  }

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
