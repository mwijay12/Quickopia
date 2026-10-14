class DriverProfile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? vehicleInfo;
  final double? rating;

  DriverProfile({
    required this.id,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.vehicleInfo,
    this.rating,
  });

  factory DriverProfile.fromMap(Map<String, dynamic> map) => DriverProfile(
        id: map['id'] as String,
        fullName: map['full_name'] as String?,
        phone: map['phone'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        vehicleInfo: map['vehicle_info'] as String?,
        rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'vehicle_info': vehicleInfo,
        'rating': rating,
      };
}
