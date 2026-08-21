import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/socket/socket_provider.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../data/auth_repository_impl.dart';
import '../data/models/user_model.dart';
import '../state/auth_notifier.dart';
import '../state/auth_state.dart';

final dioProvider = Provider<Dio>(
      (ref) => DioClient.dio,
);

final authApiProvider = Provider<AuthApi>(
      (ref) => AuthApi(
    ref.read(dioProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
      (ref) => AuthRepositoryImpl(
    ref.read(authApiProvider),
    ref.read(appCacheProvider),
      ),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
      (ref) => AuthNotifier(
    ref.read(authRepositoryProvider),
        ref.read(socketClientProvider),
      ),
);

final authCheckProvider = FutureProvider<bool>(
      (ref) async {
    final accessToken =
    await AppStorage.getAccessToken();

    final refreshToken =
    await AppStorage.getRefreshToken();

    return accessToken != null &&
        refreshToken != null;
  },
);

final splashDelayProvider = FutureProvider<bool>((ref) async {

  // Wait for 5 seconds
  await Future.delayed(const Duration(seconds: 5));

  // Also wait for the actual auth logic
  return ref.watch(authCheckProvider.future);
});

final currentUserProvider =
Provider<UserModel?>(
      (ref) =>
  ref.watch(authProvider).user,
);

// usage
// final user = ref.watch(currentUserProvider);