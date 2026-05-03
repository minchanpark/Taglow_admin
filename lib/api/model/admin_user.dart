class AdminUser {
  const AdminUser({required this.id, required this.name, required this.roles});

  final String id;
  final String name;
  final Set<String> roles;

  bool get isAdmin => roles.contains('ADMIN');
}
