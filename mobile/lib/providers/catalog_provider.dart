import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/catalog_service.dart';
import '../services/smart_search_service.dart';

enum CatalogStatus { loading, loaded, error }

class CatalogProvider extends ChangeNotifier {
  final CatalogService _service;
  final SmartSearchService _smartSearch;
  RealtimeChannel? _realtimeChannel;

  CatalogStatus status = CatalogStatus.loading;
  String? errorMessage;

  List<Category> categories = [];
  List<Product> products = [];

  String? selectedCategoryId; // null = "All"
  String searchQuery = '';

  bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  CatalogProvider({
    CatalogService? service,
    SmartSearchService? smartSearch,
  })  : _service = service ?? CatalogService(),
        _smartSearch = smartSearch ?? SmartSearchService() {
    Future.microtask(() => loadInitialData());
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    if (_isTesting || !SupabaseConfig.isConfigured) return;

    try {
      _realtimeChannel = SupabaseConfig.client
          .channel('public:products_catalog')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'products',
            callback: (payload) {
              debugPrint('CatalogProvider: Realtime products update: ${payload.eventType}');
              _refreshSilently();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'categories',
            callback: (_) {
              loadInitialData();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('CatalogProvider: Realtime subscription error: $e');
    }
  }

  Future<void> _refreshSilently() async {
    try {
      final res = await _service.fetchProducts(
        categoryId: selectedCategoryId,
        searchQuery: searchQuery,
      );
      products = res;
      status = CatalogStatus.loaded;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    status = CatalogStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      categories = await _service.fetchCategories();
      products = await _service.fetchProducts(
        categoryId: selectedCategoryId,
        searchQuery: searchQuery,
      );
      status = CatalogStatus.loaded;
    } catch (e) {
      status = CatalogStatus.error;
      errorMessage = 'Could not load products. Check your connection and try again.';
    }
    notifyListeners();
  }

  Future<void> selectCategory(String? categoryId) async {
    if (selectedCategoryId == categoryId) return;
    selectedCategoryId = categoryId;
    await _refetchProducts();
  }

  Future<void> search(String query) async {
    if (searchQuery == query) return;
    searchQuery = query;
    await _refetchProducts();
  }

  Future<void> _refetchProducts() async {
    status = CatalogStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Execute direct match search first
      var result = await _service.fetchProducts(
        categoryId: selectedCategoryId,
        searchQuery: searchQuery,
      );

      // 2. If direct query returned 0 results and query is at least 3 chars,
      // expand query bilingually via AI with graceful degradation
      if (result.isEmpty && searchQuery.trim().length >= 3) {
        final expanded = await _smartSearch.expandQuery(searchQuery);
        if (expanded.length > 1) {
          result = await _service.fetchProducts(
            categoryId: selectedCategoryId,
            searchTerms: expanded,
          );
        }
      }

      products = result;
      status = CatalogStatus.loaded;
    } catch (e) {
      status = CatalogStatus.error;
      errorMessage = 'Could not load products. Check your connection and try again.';
    }
    notifyListeners();
  }


  Future<void> refresh() => loadInitialData();
}
