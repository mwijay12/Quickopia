class Address {
  final String id;
  final String label;
  final String city;
  final String neighborhood;
  final String landmark;
  final String? houseDetails;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final String? phone;

  Address({
    required this.id,
    required this.label,
    required this.city,
    required this.neighborhood,
    required this.landmark,
    this.houseDetails,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.phone,
  });

  factory Address.fromMap(Map<String, dynamic> map) => Address(
        id: map['id'] as String,
        label: map['label'] as String? ?? 'Saved Address',
        city: map['city'] as String,
        neighborhood: map['neighborhood'] as String,
        landmark: map['landmark'] as String,
        houseDetails: map['house_details'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        isDefault: map['is_default'] as bool? ?? false,
        phone: map['phone'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'city': city,
        'neighborhood': neighborhood,
        'landmark': landmark,
        'house_details': houseDetails,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
        'phone': phone,
      };
}
