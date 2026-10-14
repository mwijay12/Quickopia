import '../config/supabase_config.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class CatalogService {
  final _client = SupabaseConfig.client;

  Future<List<Category>> fetchCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('display_order');
    return (response as List)
        .map((e) => Category.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchProducts({
    String? categoryId,
    String? searchQuery,
    List<String>? searchTerms,
  }) async {
    var query = _client.from('products').select().eq('is_available', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (searchTerms != null && searchTerms.isNotEmpty) {
      final orFilter = searchTerms
          .map((t) => 'title.ilike.%${t.trim()}%')
          .join(',');
      query = query.or(orFilter);
    } else if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.ilike('title', '%${searchQuery.trim()}%');
    }

    final response = await query.order('is_popular', ascending: false);
    return (response as List)
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
