import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/driver_profile_model.dart';
import '../services/order_tracking_service.dart';
import '../services/driver_info_service.dart';
import '../services/order_service.dart';

class OrderTrackingProvider extends ChangeNotifier {
  final OrderTrackingService _trackingService;
  final DriverInfoService _driverService;
  final OrderService _orderService;

  late Order order;
  DriverProfile? assignedDriver;
  bool isReconnecting = false;
  StreamSubscription<Order>? _sub;

  OrderTrackingProvider(
    Order initialOrder, {
    OrderTrackingService? trackingService,
    DriverInfoService? driverService,
    OrderService? orderService,
  })  : _trackingService = trackingService ?? OrderTrackingService(),
        _driverService = driverService ?? DriverInfoService(),
        _orderService = orderService ?? OrderService() {
    order = initialOrder;
    if (initialOrder.driverId != null) {
      _loadDriver(initialOrder.driverId!);
    }
    _sub = _trackingService.subscribeToOrder(initialOrder).listen((updated) {
      final driverJustAssigned =
          order.driverId != updated.driverId && updated.driverId != null;
      order = updated;
      if (driverJustAssigned) {
        _loadDriver(updated.driverId!);
      }
      notifyListeners();
    });
  }

  Future<void> _loadDriver(String driverId) async {
    assignedDriver = await _driverService.fetchDriverProfile(driverId);
    notifyListeners();
  }

  /// Manual fallback if realtime doesn't deliver an update
  Future<void> manualRefresh(String orderId) async {
    isReconnecting = true;
    notifyListeners();
    try {
      final refreshed = await _orderService.fetchOrderById(orderId);
      order = refreshed;
      if (refreshed.driverId != null) {
        await _loadDriver(refreshed.driverId!);
      }
    } catch (_) {
      // Keep previous order state if network refresh fails
    } finally {
      isReconnecting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _trackingService.dispose();
    super.dispose();
  }
}
