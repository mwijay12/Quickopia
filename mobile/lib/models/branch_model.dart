class Branch {
  final String id;
  final String name;
  final String city;
  final String? neighborhood;
  final String? landmark;
  final String? phone;

  Branch({
    required this.id,
    required this.name,
    required this.city,
    this.neighborhood,
    this.landmark,
    this.phone,
  });

  factory Branch.fromMap(Map<String, dynamic> map) => Branch(
        id: map['id'] as String,
        name: map['name'] as String,
        city: map['city'] as String,
        neighborhood: map['neighborhood'] as String?,
        landmark: map['landmark'] as String?,
        phone: map['phone'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'city': city,
        'neighborhood': neighborhood,
        'landmark': landmark,
        'phone': phone,
      };
}
