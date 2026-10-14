class OrderItem {
  final String id;
  final String productId;
  final String title;
  final double unitPriceTzs;
  final int quantity;
  final double totalTzs;

  OrderItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.unitPriceTzs,
    required this.quantity,
    required this.totalTzs,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        title: map['title'] as String,
        unitPriceTzs: (map['unit_price_tzs'] as num).toDouble(),
        quantity: map['quantity'] as int,
        totalTzs: (map['total_tzs'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'product_id': productId,
        'title': title,
        'unit_price_tzs': unitPriceTzs,
        'quantity': quantity,
        'total_tzs': totalTzs,
      };
}
