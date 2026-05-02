class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? shopCode;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.shopCode,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? json['userId'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      shopCode: json['shopCode'],
    );
  }

  bool get isSuperAdmin => role.toUpperCase() == 'SUPERADMIN';
  bool get isAdmin      => role.toUpperCase() == 'ADMIN' || isSuperAdmin;
  bool get isCustomer   => role.toUpperCase() == 'CUSTOMER';
  bool get canEdit      => isAdmin;
}
