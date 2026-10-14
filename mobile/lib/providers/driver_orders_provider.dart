import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/driver_order_service.dart';

enum DriverOrdersStatus { loading, loaded, error }

class DriverOrdersProvider extends ChangeNotifier {
  final DriverOrderService _service;
  Timer? _pollTimer;
  String? _driverId;

  DriverOrdersStatus status = DriverOrdersStatus.loading;
  List<Order> orders = [];
  List<Order> availableOrders = [];
  List<Order> completedOrders = [];
  String? errorMessage;
  bool isAccepting = false;

  DriverOrdersProvider({DriverOrderService? service})
      : _service = service ?? DriverOrderService();

  String? get currentDriverId => _driverId;

  void start(String driverId) {
    _driverId = driverId;
    refresh();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => refresh(silent: true),
    );
  }

  Future<void> refresh({bool silent = false}) async {
    if (_driverId == null) return;
    if (!silent) {
      status = DriverOrdersStatus.loading;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        _service.fetchAssignedOrders(_driverId!),
        _service.fetchAvailableOrders(),
        _service.fetchCompletedOrders(_driverId!),
      ]);

      orders = results[0];
      availableOrders = results[1];
      completedOrders = results[2];
      status = DriverOrdersStatus.loaded;
      errorMessage = null;
    } catch (e) {
      if (!silent) {
        status = DriverOrdersStatus.error;
        errorMessage = 'Could not load delivery data. Pull down to retry.';
      }
    }
    notifyListeners();
  }

  /// Driver accepts an available order
  Future<bool> acceptOrder(Order order) async {
    if (_driverId == null) return false;
    isAccepting = true;
    notifyListeners();
    try {
      await _service.acceptOrder(orderId: order.id, driverId: _driverId!);
      await refresh(silent: true);
      isAccepting = false;
      notifyListeners();
      return true;
    } catch (e) {
      isAccepting = false;
      notifyListeners();
      return false;
    }
  }

  // --- Reports & Earnings Calculations ---

  int get totalCompletedCount => completedOrders.length;

  double get totalEarningsTzs {
    return completedOrders.fold(0.0, (sum, o) => sum + o.deliveryFeeTzs);
  }

  List<Order> get todayCompletedOrders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return completedOrders.where((o) => o.createdAt.isAfter(today)).toList();
  }

  int get todayCompletedCount => todayCompletedOrders.length;

  double get todayEarningsTzs {
    return todayCompletedOrders.fold(0.0, (sum, o) => sum + o.deliveryFeeTzs);
  }

  double get settledPayoutTzs {
    return completedOrders
        .where((o) => o.paymentStatus == 'paid')
        .fold(0.0, (sum, o) => sum + o.deliveryFeeTzs);
  }

  double get pendingPayoutTzs {
    return completedOrders
        .where((o) => o.paymentStatus != 'paid')
        .fold(0.0, (sum, o) => sum + o.deliveryFeeTzs);
  }

  void clear() {
    _pollTimer?.cancel();
    _driverId = null;
    orders = [];
    availableOrders = [];
    completedOrders = [];
    status = DriverOrdersStatus.loading;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
