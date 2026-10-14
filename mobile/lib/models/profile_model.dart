class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String role; // 'customer' | 'driver' | 'admin'
  final String? branchId;
  final String? referralCode;
  final String? referredBy;
  final int referralCount;
  final String? avatarUrl;
  final String? bio;
  final String? vehicleInfo;
  final double? rating;

  Profile({
    required this.id,
    this.fullName,
    this.phone,
    required this.role,
    this.branchId,
    this.referralCode,
    this.referredBy,
    this.referralCount = 0,
    this.avatarUrl,
    this.bio,
    this.vehicleInfo,
    this.rating,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      fullName: (map['full_name'] ?? map['name']) as String?,
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'customer',
      branchId: map['branch_id'] as String?,
      referralCode: map['referral_code'] as String?,
      referredBy: map['referred_by'] as String?,
      referralCount: (map['referral_count'] as num?)?.toInt() ?? 0,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      vehicleInfo: map['vehicle_info'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'branch_id': branchId,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'referral_count': referralCount,
      'avatar_url': avatarUrl,
      'bio': bio,
      'vehicle_info': vehicleInfo,
      'rating': rating,
    };
  }

  bool get isCustomer => role == 'customer';
  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin';
}
