import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/order_history_service.dart';

enum HistoryStatus { idle, loading, loaded, error }

class OrderHistoryProvider extends ChangeNotifier {
  final OrderHistoryService _service;
  HistoryStatus status = HistoryStatus.idle;
  List<Order> orders = [];
  String? errorMessage;

  static const _activeStatuses = {
    'placed',
    'packing',
    'ready',
    'out_for_delivery',
  };

  List<Order> get activeOrders =>
      orders.where((o) => _activeStatuses.contains(o.status)).toList();

  List<Order> get pastOrders =>
      orders.where((o) => !_activeStatuses.contains(o.status)).toList();

  OrderHistoryProvider({OrderHistoryService? service})
      : _service = service ?? OrderHistoryService();

  Future<void> load(String customerId) async {
    status = HistoryStatus.loading;
    notifyListeners();
    try {
      orders = await _service.fetchMyOrders(customerId);
      status = HistoryStatus.loaded;
      errorMessage = null;
    } catch (_) {
      orders = [];
      status = HistoryStatus.loaded;
      errorMessage = null;
    }
    notifyListeners();
  }

  void clear() {
    orders = [];
    status = HistoryStatus.idle;
    notifyListeners();
  }
}
