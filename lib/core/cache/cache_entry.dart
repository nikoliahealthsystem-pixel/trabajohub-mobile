class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  const CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > ttl;

  bool get isStale =>
      DateTime.now().difference(cachedAt) > (ttl * 0.75);
}