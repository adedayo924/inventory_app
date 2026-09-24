class UserModel {
  final int id;
  final int? storeId;
  final String name;
  final String email;
  final String role; // 'admin', 'manager', 'cashier'
  final bool isActive;
  final bool mustChangePassword;

  UserModel({
    required this.id,
    this.storeId,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.mustChangePassword = false,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isManager => role.toLowerCase() == 'manager' || isAdmin;
  bool get isCashier => role.toLowerCase() == 'cashier' || isManager;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int? ?? 0,
      storeId: map['store_id'] as int?,
      name: map['name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'cashier',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      mustChangePassword: (map['must_change_password'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'must_change_password': mustChangePassword ? 1 : 0,
    };
  }

  UserModel copyWith({
    int? id,
    int? storeId,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    bool? mustChangePassword,
  }) {
    return UserModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}
