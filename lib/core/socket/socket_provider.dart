import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'socket_client.dart';

final socketClientProvider = Provider<SocketClient>((ref) {
  return SocketClient.instance;
});