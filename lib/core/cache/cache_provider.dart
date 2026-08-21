import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_cache.dart';

final appCacheProvider = Provider<AppCache>((ref) => AppCache.instance);