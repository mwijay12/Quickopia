import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/hero_banner_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/admin_service.dart';

enum AdminStatus { idle, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  final AdminService _service;

  AdminStatus status = AdminStatus.idle;
  String? errorMessage;

  List<Order> orders = [];
  List<Product> products = [];
  AdminDashboardStats stats = const AdminDashboardStats();

  String selectedStatusFilter = 'all';
  String productSearchQuery = '';
  bool isHolidayCampaignActive = true;

  List<HeroBannerSlide> heroBannerSlides = List.from(HeroBannerSlide.defaultSlides);
  RealtimeChannel? _heroBannerChannel;

  AdminProvider({AdminService? service}) : _service = service ?? AdminService() {
    _loadHeroSlides();
    _subscribeToHeroBannerChanges();
  }

  bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  void _subscribeToHeroBannerChanges() {
    if (_isTesting || !SupabaseConfig.isConfigured) return;
    try {
      _heroBannerChannel = SupabaseConfig.client
          .channel('public:hero_banners_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'hero_banners',
            callback: (_) => _loadHeroSlides(),
          );
      _heroBannerChannel?.subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_heroBannerChannel != null) {
      try {
        SupabaseConfig.client.removeChannel(_heroBannerChannel!);
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _loadHeroSlides() async {
    try {
      final response = await SupabaseConfig.client
          .from('hero_banners')
          .select('*')
          .eq('is_active', true)
          .order('display_order', ascending: true);
      if (response.isNotEmpty) {
        heroBannerSlides = response
            .asMap()
            .entries
            .map((e) => HeroBannerSlide.fromMap(e.value, e.key))
            .toList();
        notifyListeners();
        return;
      }
    } catch (_) {
      // Fallback to local storage if offline
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = <HeroBannerSlide>[];
      for (final slide in heroBannerSlides) {
        final savedBg = prefs.getString('hero_slide_bg_${slide.id}');
        if (savedBg != null && savedBg.isNotEmpty) {
          updated.add(slide.copyWith(imageUrl: savedBg));
        } else {
          updated.add(slide);
        }
      }
      heroBannerSlides = updated;
      notifyListeners();
    } catch (_) {}
  }

  List<Order> get filteredOrders {
    if (selectedStatusFilter == 'all') return orders;
    return orders.where((o) => o.status == selectedStatusFilter).toList();
  }

  List<Product> get filteredProducts {
    if (productSearchQuery.isEmpty) return products;
    final q = productSearchQuery.toLowerCase();
    return products.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  Future<void> loadData() async {
    status = AdminStatus.loading;
    notifyListeners();

    try {
      orders = await _service.fetchAllOrders();
      products = await _service.fetchAllProducts();
      stats = _service.computeStats(orders, products);
      status = AdminStatus.loaded;
    } catch (e) {
      status = AdminStatus.error;
      errorMessage = 'Could not load admin data: $e';
    }

    notifyListeners();
  }

  void filterOrders(String statusFilter) {
    selectedStatusFilter = statusFilter;
    notifyListeners();
  }

  void searchProducts(String query) {
    productSearchQuery = query;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _service.updateOrderStatus(orderId, newStatus);
      // Update locally
      final index = orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final old = orders[index];
        orders[index] = Order(
          id: old.id,
          orderNumber: old.orderNumber,
          fulfillmentType: old.fulfillmentType,
          status: newStatus,
          pickupCode: old.pickupCode,
          subtotalTzs: old.subtotalTzs,
          deliveryFeeTzs: old.deliveryFeeTzs,
          totalAmountTzs: old.totalAmountTzs,
          paymentMethod: old.paymentMethod,
          paymentStatus: old.paymentStatus,
          createdAt: old.createdAt,
          items: old.items,
          driverId: old.driverId,
          deliveryNeighborhood: old.deliveryNeighborhood,
          deliveryLandmark: old.deliveryLandmark,
          customerPhone: old.customerPhone,
          deliveryLatitude: old.deliveryLatitude,
          deliveryLongitude: old.deliveryLongitude,
        );
        stats = _service.computeStats(orders, products);
        notifyListeners();
      }
      return true;
    } catch (e) {
      errorMessage = 'Failed to update order: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProductPriceAndStock({
    required String productId,
    required double newPriceTzs,
    required int newStockQuantity,
    bool? isAvailable,
  }) async {
    try {
      await _service.updateProductPriceAndStock(
        productId: productId,
        newPriceTzs: newPriceTzs,
        newStockQuantity: newStockQuantity,
        isAvailable: isAvailable,
      );

      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final old = products[index];
        products[index] = Product(
          id: old.id,
          categoryId: old.categoryId,
          title: old.title,
          description: old.description,
          priceTzs: newPriceTzs,
          imageUrl: old.imageUrl,
          stockQuantity: newStockQuantity,
          unit: old.unit,
          isAvailable: isAvailable ?? old.isAvailable,
          isPopular: old.isPopular,
          rating: old.rating,
          reviewCount: old.reviewCount,
          galleryUrls: old.galleryUrls,
        );
        stats = _service.computeStats(orders, products);
        notifyListeners();
      }
      return true;
    } catch (e) {
      errorMessage = 'Failed to update product: $e';
      notifyListeners();
      return false;
    }
  }

  void toggleHolidayCampaign(bool active) {
    isHolidayCampaignActive = active;
    notifyListeners();
  }

  Future<void> updateSlideBgImage(int index, String? imageUrl) async {
    if (index >= 0 && index < heroBannerSlides.length) {
      final updated = heroBannerSlides[index].copyWith(imageUrl: imageUrl);
      heroBannerSlides[index] = updated;
      notifyListeners();
      try {
        await SupabaseConfig.client
            .from('hero_banners')
            .update({'image_url': imageUrl})
            .eq('id', updated.id);
      } catch (_) {}
      try {
        final prefs = await SharedPreferences.getInstance();
        if (imageUrl != null && imageUrl.trim().isNotEmpty) {
          await prefs.setString('hero_slide_bg_${updated.id}', imageUrl.trim());
        } else {
          await prefs.remove('hero_slide_bg_${updated.id}');
        }
      } catch (_) {}
    }
  }
}
