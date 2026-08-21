import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/features/auth/presentation/splash_screen.dart';
import 'package:trabajo_hub/features/auth/providers/auth_provider.dart';

import 'core/services/notification_service.dart';
import 'core/utils/check.dart';
import 'firebase_options.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You must re-initialize Firebase in the background isolate
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint("Handling a background message: ${message.messageId}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 15));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // final expiry = DateTime(2026, 7, 27);
    //
    // if (DateTime.now().isAfter(expiry)) {
    //   runApp(const checks());
    // } else {
      runApp(
        const ProviderScope(
          child: TrabajoHub(),
        ),
      );
    // }
  }).then((_) async {
    // Initialize Local Notifications
    await NotificationService.init();
    // Setup listener AFTER runApp
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final data = message.data;
      final title = notification?.title ?? data['title'] ?? 'New Notification';
      final body = notification?.body ?? data['body'] ?? '';
      NotificationService.showNotification(title: title, body: body);
    });
  });
}

class TrabajoHub extends ConsumerStatefulWidget {
  const TrabajoHub({super.key});

  @override
  ConsumerState<TrabajoHub> createState() => _TrabajoHubState();
}

class _TrabajoHubState extends ConsumerState<TrabajoHub> {
  @override
  void initState() {
    super.initState();
    // ref is available here in ConsumerStatefulWidget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initializeAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color.fromARGB(255, 243, 243, 243),
          appBarTheme: const AppBarTheme(
            surfaceTintColor: Color.fromARGB(255, 243, 243, 243),
            centerTitle: true,
            iconTheme: IconThemeData(),
            backgroundColor: Color.fromARGB(255, 243, 243, 243),
          ),
          applyElevationOverlayColor: false,
          fontFamily: 'Poppins',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}