import 'dart:async';
import '../config/supabase_config.dart';

class SmartSearchService {
  final _client = SupabaseConfig.client;

  // Local memory cache for session efficiency
  final Map<String, List<String>> _memoryCache = {};

  /// Expands a search query into bilingual synonyms/related terms.
  /// Gracefully degrades to `[query]` on any error, timeout, or network issue.
  Future<List<String>> expandQuery(String rawQuery) async {
    final query = rawQuery.trim().toLowerCase();
    if (query.length < 3) return [query];

    // 1. Check in-memory session cache
    if (_memoryCache.containsKey(query)) {
      return _memoryCache[query]!;
    }

    try {
      // 2. Check Postgres search_query_cache table directly (fastest, zero Gemini calls)
      final cachedRow = await _client
          .from('search_query_cache')
          .select('expanded_terms')
          .eq('query_normalized', query)
          .maybeSingle()
          .timeout(const Duration(milliseconds: 1200));

      if (cachedRow != null && cachedRow['expanded_terms'] != null) {
        final terms = List<String>.from(cachedRow['expanded_terms'] as List);
        if (terms.isNotEmpty) {
          _memoryCache[query] = terms;
          return terms;
        }
      }

      // 3. Invoke Supabase Edge Function with strict 1.5s timeout
      final res = await _client.functions
          .invoke(
            'expand-search-query',
            body: {'query': query},
          )
          .timeout(const Duration(milliseconds: 1500));

      if (res.status == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (data['terms'] is List && (data['terms'] as List).isNotEmpty) {
          final terms = List<String>.from(data['terms'] as List);
          _memoryCache[query] = terms;
          return terms;
        }
      }
    } catch (_) {
      // Graceful degradation: silently fall back to direct query on any timeout/error
    }

    // Default fallback
    return [query];
  }
}
