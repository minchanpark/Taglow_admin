import 'admin_user.dart';

class AdminAuthSession {
  const AdminAuthSession({
    required this.user,
    required this.isLoading,
    this.errorMessage,
  });

  final AdminUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;
  bool get canManage => user?.isAdmin ?? false;
}
