import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _storageKey = 'quickopia_favorites_v1';
  final Set<String> _favoriteIds = {};
  bool _isLoaded = false;

  FavoritesProvider() {
    _loadFromDisk();
  }

  bool get isLoaded => _isLoaded;
  int get count => _favoriteIds.length;
  List<String> get favoriteIds => _favoriteIds.toList();

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey);
      if (list != null) {
        _favoriteIds.addAll(list);
      }
    } catch (e) {
      debugPrint('[FavoritesProvider] Error loading favorites: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _favoriteIds.toList());
    } catch (e) {
      debugPrint('[FavoritesProvider] Error saving favorites: $e');
    }
  }

  /// Toggles favorite status and returns true if now favorited, false if unfavorited.
  Future<bool> toggleFavorite(String productId) async {
    final bool nowFav;
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      nowFav = false;
    } else {
      _favoriteIds.add(productId);
      nowFav = true;
    }
    notifyListeners();
    await _persist();
    return nowFav;
  }
}
