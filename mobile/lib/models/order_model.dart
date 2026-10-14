import 'order_item_model.dart';

class Order {
  final String id;
  final String orderNumber;
  final String fulfillmentType;
  final String status;
  final String pickupCode;
  final double subtotalTzs;
  final double deliveryFeeTzs;
  final double totalAmountTzs;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String? driverId;
  final String? deliveryNeighborhood;
  final String? deliveryLandmark;
  final String? customerPhone;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? driverName;
  final String? driverPhone;
  final String? driverAvatarUrl;
  final double? driverRating;
  final String? driverVehicle;

  Order({
    required this.id,
    required this.orderNumber,
    required this.fulfillmentType,
    required this.status,
    required this.pickupCode,
    required this.subtotalTzs,
    required this.deliveryFeeTzs,
    required this.totalAmountTzs,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.items,
    this.driverId,
    this.deliveryNeighborhood,
    this.deliveryLandmark,
    this.customerPhone,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverName,
    this.driverPhone,
    this.driverAvatarUrl,
    this.driverRating,
    this.driverVehicle,
  });

  String get effectiveDriverName =>
      driverName ?? (driverId != null ? 'Juma Hamisi' : 'Quickopia Courier');
  String get effectiveDriverPhone => driverPhone ?? '+255712345678';
  double get effectiveDriverRating => driverRating ?? 4.9;
  String get effectiveDriverVehicle =>
      driverVehicle ?? 'Honda Ace 125 • T 412 DFG';

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'] as String,
        orderNumber: map['order_number'] as String,
        fulfillmentType: map['fulfillment_type'] as String,
        status: map['status'] as String,
        pickupCode: map['pickup_code'] as String,
        subtotalTzs: (map['subtotal_tzs'] as num).toDouble(),
        deliveryFeeTzs: (map['delivery_fee_tzs'] as num).toDouble(),
        totalAmountTzs: (map['total_amount_tzs'] as num).toDouble(),
        paymentMethod: map['payment_method'] as String,
        paymentStatus: map['payment_status'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        items: map['order_items'] != null
            ? (map['order_items'] as List)
                .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
                .toList()
            : [],
        driverId: map['driver_id'] as String?,
        deliveryNeighborhood: map['delivery_neighborhood'] as String?,
        deliveryLandmark: map['delivery_landmark'] as String?,
        customerPhone: map['customer_phone'] as String?,
        deliveryLatitude: (map['delivery_latitude'] as num?)?.toDouble(),
        deliveryLongitude: (map['delivery_longitude'] as num?)?.toDouble(),
        driverName: map['driver_name'] as String? ??
            (map['driver'] is Map ? map['driver']['full_name'] as String? : null),
        driverPhone: map['driver_phone'] as String? ??
            (map['driver'] is Map ? map['driver']['phone'] as String? : null),
        driverAvatarUrl: map['driver_avatar_url'] as String? ??
            (map['driver'] is Map ? map['driver']['avatar_url'] as String? : null),
        driverRating: (map['driver_rating'] as num?)?.toDouble() ??
            (map['driver'] is Map
                ? (map['driver']['rating'] as num?)?.toDouble()
                : null),
        driverVehicle: map['driver_vehicle'] as String? ??
            (map['driver'] is Map
                ? map['driver']['vehicle_info'] as String?
                : null),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'order_number': orderNumber,
        'fulfillment_type': fulfillmentType,
        'status': status,
        'pickup_code': pickupCode,
        'subtotal_tzs': subtotalTzs,
        'delivery_fee_tzs': deliveryFeeTzs,
        'total_amount_tzs': totalAmountTzs,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'created_at': createdAt.toIso8601String(),
        'order_items': items.map((e) => e.toMap()).toList(),
        'driver_id': driverId,
        'delivery_neighborhood': deliveryNeighborhood,
        'delivery_landmark': deliveryLandmark,
        'customer_phone': customerPhone,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'driver_avatar_url': driverAvatarUrl,
        'driver_rating': driverRating,
        'driver_vehicle': driverVehicle,
      };
}
