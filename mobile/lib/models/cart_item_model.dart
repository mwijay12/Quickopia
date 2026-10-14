class CartItem {
  final String productId;
  final String title;
  final double priceTzs;
  final String? unit;
  final String? imageUrl;
  final int stockCeiling; // stock available at time of adding — caps local quantity
  int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.priceTzs,
    this.unit,
    this.imageUrl,
    required this.stockCeiling,
    this.quantity = 1,
  });

  double get lineTotalTzs => priceTzs * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'title': title,
        'priceTzs': priceTzs,
        'unit': unit,
        'imageUrl': imageUrl,
        'stockCeiling': stockCeiling,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        title: json['title'] as String,
        priceTzs: (json['priceTzs'] as num).toDouble(),
        unit: json['unit'] as String?,
        imageUrl: json['imageUrl'] as String?,
        stockCeiling: json['stockCeiling'] as int? ?? 99,
        quantity: json['quantity'] as int? ?? 1,
      );
}
