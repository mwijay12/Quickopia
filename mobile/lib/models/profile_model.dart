class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String role; // 'customer' | 'driver' | 'admin'
  final String? branchId;

  Profile({
    required this.id,
    this.fullName,
    this.phone,
    required this.role,
    this.branchId,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'customer',
      branchId: map['branch_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'branch_id': branchId,
    };
  }

  bool get isCustomer => role == 'customer';
  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin';
}
