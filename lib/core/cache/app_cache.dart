import 'cache_entry.dart';

class AppCache {
  AppCache._();
  static final AppCache instance = AppCache._();

  final Map<String, CacheEntry<dynamic>> _store = {};

  // ── Write ───────────────────────────────────────────────

  void set<T>(String key, T data, Duration ttl) {
    _store[key] = CacheEntry<T>(
      data: data,
      cachedAt: DateTime.now(),
      ttl: ttl,
    );
  }

  // ── Read ────────────────────────────────────────────────

  CacheEntry<T>? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry as CacheEntry<T>;
  }

  T? getValue<T>(String key) => get<T>(key)?.data;

  bool has(String key) => get(key) != null;

  bool isStale(String key) => get(key)?.isStale ?? true;

  // ── Invalidation ─────────────────────────────────────────

  /// Remove a single key
  void invalidate(String key) => _store.remove(key);

  /// Remove all keys matching a prefix — e.g. invalidatePrefix('shifts')
  void invalidatePrefix(String prefix) {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Remove all keys matching a tag list stored alongside entries
  void clear() => _store.clear();

  /// Returns all currently cached keys (for debugging)
  List<String> get keys => _store.keys.toList();
}