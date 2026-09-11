import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/features/auth/presentation/splash_screen.dart';
import 'package:trabajo_hub/features/auth/providers/auth_provider.dart';

import 'active_session.dart';
import 'core/services/notification_service.dart';
import 'features/shifts/presentation/shift_detail_screen.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 15));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: TrabajoHub()));
}

class TrabajoHub extends ConsumerStatefulWidget {
  const TrabajoHub({super.key});

  @override
  ConsumerState<TrabajoHub> createState() => _TrabajoHubState();
}

class _TrabajoHubState extends ConsumerState<TrabajoHub> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final AppLinks _appLinks;

  StreamSubscription<Uri>? _appLinksSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  RemoteMessage? _pendingNotificationMessage;
  String? _pendingLocalNotificationPayload;

  bool _notificationHandlersInitialized = false;
  bool _processingNotificationTap = false;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    _appLinksSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (_) {},
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).initializeAuth();

      await _initializeNotificationHandling();

      await _processPendingNotification();
    });
  }

  Future<void> _initializeNotificationHandling() async {
    if (_notificationHandlersInitialized) return;

    _notificationHandlersInitialized = true;

    await NotificationService.init(
      onNotificationTap: _handleLocalNotificationTap,
    );

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationMessageTap,
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _pendingNotificationMessage = initialMessage;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'New Notification';

    final body = notification?.body ?? data['body'] ?? '';

    final payload = _encodeNotificationPayload(data);

    await NotificationService.showNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  void _handleNotificationMessageTap(RemoteMessage message) {
    _pendingNotificationMessage = message;
    _processPendingNotification();
  }

  void _handleLocalNotificationTap(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;

    _pendingLocalNotificationPayload = payload;
    _processPendingNotification();
  }

  Future<void> _processPendingNotification() async {
    if (!mounted || _processingNotificationTap) return;

    final message = _pendingNotificationMessage;
    final localPayload = _pendingLocalNotificationPayload;

    if (message == null && localPayload == null) return;

    _processingNotificationTap = true;

    try {
      final loggedIn = await ref.read(authCheckProvider.future);

      if (!loggedIn || !mounted) {
        return;
      }

      Map<String, dynamic> data = {};

      if (message != null) {
        data = Map<String, dynamic>.from(message.data);
      } else if (localPayload != null) {
        data = _decodeNotificationPayload(localPayload);
      }

      _pendingNotificationMessage = null;
      _pendingLocalNotificationPayload = null;

      await _openNotificationDestination(data);
    } finally {
      _processingNotificationTap = false;
    }
  }

  Future<void> _openNotificationDestination(Map<String, dynamic> data) async {
    if (!mounted) return;

    final navigator = _navigatorKey.currentState;

    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNotificationDestination(data);
      });
      return;
    }

    final type = (data['type'] ?? data['notification_type'] ?? '')
        .toString()
        .toLowerCase();

    final shiftId = _firstNonEmpty([
      data['shiftId'],
      data['shift_id'],
      data['shiftID'],
    ]);

    /*
     * SHIFT NOTIFICATIONS
     *
     * If the notification contains a shift ID, open that
     * specific shift directly.
     */
    if (shiftId != null &&
        (type.isEmpty ||
            type.contains('shift') ||
            type.contains('booking') ||
            type.contains('schedule'))) {
      navigator.push(
        MaterialPageRoute(builder: (_) => ShiftDetailScreen(shiftId: shiftId)),
      );

      return;
    }

    /*
     * MESSAGE NOTIFICATIONS
     *
     * Open the Messages tab.
     */
    if (type.contains('message') ||
        type.contains('chat') ||
        type.contains('conversation')) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 3)),
        (route) => false,
      );

      return;
    }

    /*
     * VISIT NOTIFICATIONS
     */
    if (type.contains('visit')) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 2)),
        (route) => false,
      );

      return;
    }

    /*
     * PROFILE / ACCOUNT NOTIFICATIONS
     */
    if (type.contains('profile') ||
        type.contains('credential') ||
        type.contains('account')) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 4)),
        (route) => false,
      );

      return;
    }

    /*
     * GENERAL NOTIFICATION
     *
     * Fall back to the notification screen if we do not
     * recognize the destination.
     */
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 0)),
      (route) => false,
    );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final stringValue = value?.toString().trim();

      if (stringValue != null && stringValue.isNotEmpty) {
        return stringValue;
      }
    }

    return null;
  }

  String _encodeNotificationPayload(Map<String, dynamic> data) {
    final entries = data.entries.map((entry) {
      final key = Uri.encodeComponent(entry.key);
      final value = Uri.encodeComponent(entry.value.toString());

      return '$key=$value';
    });

    return entries.join('&');
  }

  Map<String, dynamic> _decodeNotificationPayload(String payload) {
    final result = <String, dynamic>{};

    for (final part in payload.split('&')) {
      if (part.trim().isEmpty) continue;

      final separatorIndex = part.indexOf('=');

      if (separatorIndex <= 0) continue;

      final key = Uri.decodeComponent(part.substring(0, separatorIndex));

      final value = Uri.decodeComponent(part.substring(separatorIndex + 1));

      result[key] = value;
    }

    return result;
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    final isStripeReturn =
        uri.scheme == 'https' &&
        uri.host == 'app.trabajohub.com' &&
        uri.path == '/mobile/stripe-return';

    if (!isStripeReturn) return;

    final loggedIn = await ref.read(authCheckProvider.future);

    if (!loggedIn || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ActiveSession(pageIndex: 4)),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _appLinksSubscription?.cancel();
    _foregroundMessageSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
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
