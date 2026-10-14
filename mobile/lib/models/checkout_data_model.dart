class CheckoutData {
  final String fulfillmentType; // 'delivery' | 'pickup'
  final String? city;
  final String? neighborhood;
  final String? landmark;
  final String? houseDetails;
  final double? latitude;
  final double? longitude;
  final String customerPhone;
  final String paymentMethod; // 'cod' | 'lipa_namba'
  final String? paymentReference;
  final double subtotalTzs;
  final double deliveryFeeTzs;
  final double totalTzs;

  CheckoutData({
    required this.fulfillmentType,
    this.city,
    this.neighborhood,
    this.landmark,
    this.houseDetails,
    this.latitude,
    this.longitude,
    required this.customerPhone,
    required this.paymentMethod,
    this.paymentReference,
    required this.subtotalTzs,
    required this.deliveryFeeTzs,
    required this.totalTzs,
  });
}
