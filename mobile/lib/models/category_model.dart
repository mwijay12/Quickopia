class Category {
  final String id;
  final String name;
  final String? nameSw;
  final String? icon;
  final int displayOrder;

  Category({
    required this.id,
    required this.name,
    this.nameSw,
    this.icon,
    required this.displayOrder,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        nameSw: map['name_sw'] as String?,
        icon: map['icon'] as String?,
        displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'name_sw': nameSw,
        'icon': icon,
        'display_order': displayOrder,
      };
}
